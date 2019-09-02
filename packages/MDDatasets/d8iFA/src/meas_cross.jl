#MDDatasets: "cross" measurements
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#

#Constants used to filter out undesired crossings:
#-------------------------------------------------------------------------------
#RISE & FALL are mutually exclusive (but user can want both):
const XINGTYPE_RISE = UInt(0x1)
const XINGTYPE_FALL = UInt(0x2)
#const XINGTYPE_DIRMASK = UInt(0x3)
#FLAT & SING are mutually excluive (but user can want both):
const XINGTYPE_SING = UInt(0x4) #Does not cross @ single point
const XINGTYPE_FLAT = UInt(0x8) #Does not cross @ single point
#THRU & REV are mutually exclusive (but user can want both):
const XINGTYPE_THRU = UInt(0x10) #Goes through
const XINGTYPE_REV = UInt(0x20) #Reverses out.  Does not fully cross
const XINGTYPE_FIRSTLAST = UInt(0x40) #First/last point leaving/entering zero state

const XINGTYPE_ALL =
	XINGTYPE_RISE|XINGTYPE_FALL |
	XINGTYPE_SING|XINGTYPE_FLAT |
	XINGTYPE_THRU|XINGTYPE_REV|XINGTYPE_FIRSTLAST


#==Types
===============================================================================#

struct CrossType
	v::UInt
end

function CrossType(;rise=true, fall=true, sing=true, flat=true, thru=true, rev=false, firstlast=false)
	result = rise*XINGTYPE_RISE | fall*XINGTYPE_FALL |
	         sing*XINGTYPE_SING | flat*XINGTYPE_FLAT |
	         thru*XINGTYPE_THRU | rev*XINGTYPE_REV | firstlast*XINGTYPE_FIRSTLAST
	return CrossType(result)
end

function CrossType(id::Symbol)
	if :all == id
		return CrossType(rise=true, fall=true, sing=true, flat=true, thru=true, rev=true, firstlast=true)
	elseif :default == id
		return CrossType()
	elseif :rise == id
		return CrossType(rise=true, fall=false)
	elseif :fall == id
		return CrossType(rise=false, fall=true)
	elseif :risefall == id
		return CrossType(rise=true, fall=true)
	else
		throw("Unknown crossing-type preset: $id")
	end
end


#==Main algorithm
===============================================================================#

#Finds all zero crossing indices in a dataset, up to nmax.
#nmax = 0: find all crossings
#-------------------------------------------------------------------------------
function icross(d::DataF1, nmax::Integer, xstart::Real, allow::CrossType)
	#TODO: make into function if can force inline
	#(SGNTOXINGDIR >> (1+Int(sgncur)))&0x3 returns the type of xing:
	SGNTOXINGDIR = XINGTYPE_FALL|XINGTYPE_RISE<<2 #WANTCONST
	EMPTYRESULT = Limits1D{Int}[] #WANTCONST
	allow = allow.v #Get value

	validate(d); #Expensive, but might avoid headaches
	x = d.x; y = d.y #shortcuts
	ny = length(y)
	if ny < 1; return EMPTYRESULT; end
	xstart = max(x[1], xstart) #Simplify algorithm below
	if xstart > x[end]; return EMPTYRESULT; end
	nmax = nmax<1 ? ny : min(nmax, ny)
	idx = Vector{Limits1D{Int}}(undef, nmax) #resultant array of indices
	n = 0 #Index into idx[]
	i = 1 #Index into x/y[]
	while x[i] < xstart #Fast-forward to start point
		i+=1
	end
	#Here: x[i] >= xstart

	if x[i] > xstart
		i -= 1 #ok: xstart = max(x[1], xstart)
	end
	istart = i
	ystart = value(d, x=xstart) #TODO: direct interp, instead of using value()
	sgncur = sign(ystart)
	lastnzpos = 0; #Pretend like this is the start of the data
	if (sgncur != 0); lastnzpos = i; end

	#Move up to first non-zero value... if not already done:
	while lastnzpos < 1 && i < ny
		i+=1
		sgncur = sign(y[i])
		if (sgncur != 0); lastnzpos = i; end
	end
	if lastnzpos < 1; return EMPTYRESULT; end
	#Here: y[i] @ first nonzero value since xstart

	#Register first crossing if all initial values were zeros since xstart:
	if 0 == ystart
		xingdir = (SGNTOXINGDIR >> (1+Int(sgncur)))&0x3
		xingtype = XINGTYPE_FIRSTLAST
		xingtype |= xingdir

		if allow & xingtype == xingtype
			needsinterp = (1==lastnzpos-istart && y[istart] != 0)
			n+=1
			if needsinterp
				idx[n] = Limits1D(istart, istart+1)
			else
				idx[n] = Limits1D(lastnzpos-1, lastnzpos-1)
			end
		end
	end

	sgnenter=sgncur #Not really needed; mostly a declaration
	posfirstzero = 0 #No longer reading a zero sequence
	sgnprev = sgncur
	while i < ny
		i+=1
		sgncur = sign(y[i])
		if sgncur != sgnprev
			xingdir = (SGNTOXINGDIR >> (1+Int(sgncur)))&0x3
			if posfirstzero > 0
				xingtype = (posfirstzero == i-1 ? XINGTYPE_SING : XINGTYPE_FLAT)
				xingtype |= (0 == sgnenter+sgncur ? XINGTYPE_THRU : XINGTYPE_REV)
				xingtype |= xingdir
				if allow & xingtype == xingtype
					n+=1
					idx[n] = Limits1D(posfirstzero, i-1)
				end
				posfirstzero = 0
			elseif 0==sgncur
				sgnenter=sgnprev
				posfirstzero = i
			else
				xingtype = XINGTYPE_THRU|XINGTYPE_SING
				xingtype |= (SGNTOXINGDIR >> (1+Int(sgncur)))&0x3
				xingtype |= xingdir
				if allow & xingtype == xingtype
					n+=1
					idx[n] = Limits1D(i-1, i)
				end
			end
			if n >= nmax; break; end
			sgnprev = sgncur
		end
	end

	reachedend = (i >= ny)
	if reachedend && posfirstzero>0
		xingdir = (SGNTOXINGDIR >> (1-Int(sgnenter)))&0x3
		xingtype = XINGTYPE_FIRSTLAST
		xingtype |= xingdir
		if allow & xingtype == xingtype
			n+=1
			idx[n] = Limits1D(posfirstzero, posfirstzero)
		end
	end

	return resize!(idx, n)
end

#TODO: what about infinitiy? convert(Float32,NaN)
#-------------------------------------------------------------------------------
function xveccross(d::DataF1{TX,TY}, nmax::Integer,
	xstart::Real, allow::CrossType) where {TX<:Number, TY<:Number}
	idx = icross(d, nmax, xstart, allow)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	result = Vector{TR}(undef, length(idx))
	for i in 1:length(idx)
		rng = idx[i]
		x1 = d.x[rng.min]; y1 = d.y[rng.min]
		if zero(TY) == y1
			result[i] = (d.x[rng.max] + x1)/2
		else
			Δy = d.y[rng.max] - y1
			Δx = d.x[rng.max] - x1
			result[i] = (0-y1)*(Δx/Δy)+x1
		end
	end
	return result
end

#-------------------------------------------------------------------------------
function xcross(d::DataF1; nmax::Integer=0, xstart::Real=-Inf,
	allow::CrossType=CrossType())
	x = xveccross(d, nmax, xstart, allow)
	return DataF1(x, x)
end
function xcross(::DS{:event}, d::DataF1, args...; kwargs...)
	d = xcross(d, args...;kwargs...)
	return DataF1(collect(1:length(d.x)), d.y)
end

#xcross1: return a single crossing point (new name for type stability)
#-------------------------------------------------------------------------------
function xcross1(d::DataF1; n::Integer=1, xstart::Real=-Inf,
	allow::CrossType=CrossType())
	n = max(n, 1)
	x = xveccross(d, n, xstart, allow)
	if length(x) < n
		return convert(eltype(x), NaN) #TODO: Will fail with int.  Use NA.
	else
		return x[n]
	end
end

#TODO: Make more efficient (don't use "value")
#-------------------------------------------------------------------------------
function ycross(d1::DataF1{TX,TY}, d2::T; nmax::Integer=0, xstart::Real=-Inf,
	allow::CrossType=CrossType()) where {TX<:Number, TY<:Number, T<:DF1_Num}
	x = xveccross(d1-d2, nmax, xstart, allow)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	y = Vector{TR}(undef, length(x))
	for i in 1:length(x)
		y[i] = value(d1, x=x[i])
	end
	return DataF1(x, y)
end
function ycross(::DS{:event}, d1::DataF1, d2::T, args...; kwargs...) where T<:DF1_Num
	d = ycross(args...;kwargs...)
	return DataF1(collect(1:length(d.x)), d.y)
end

#ycross1: return a single crossing point (new name for type stability)
#-------------------------------------------------------------------------------
function ycross1(d1::DataF1{TX,TY}, d2::T; n::Integer=1,	xstart::Real=-Inf,
	allow::CrossType=CrossType()) where {TX<:Number, TY<:Number, T<:DF1_Num}
	n = max(n, 1)
	x = xveccross(d1-d2, n, xstart, allow)
	TR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	if length(x) < n
		return convert(TR, NaN) #TODO: Will fail with int.  Use NA.
	else
		return value(d1, x=x[n])
	end
end


#Last line
