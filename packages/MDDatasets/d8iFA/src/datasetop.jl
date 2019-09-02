#MDDatasets: Dataset operations
#TODO: optimize operations so they run faster
#TODO: ensure length(v)>1?
#TODO: add xaty?
#-------------------------------------------------------------------------------


#==Data accessors
===============================================================================#

#Obtain a dataset of the x-values
#-------------------------------------------------------------------------------
xval(d::DataF1) = DataF1(d.x, copy(d.x)) #TODO: is copy necessary?  User should not modify

xmax(d::DataF1) = maximum(d.x)
xmin(d::DataF1) = minimum(d.x)


#Element-by-element difference of y-values:
#(shift x-values @ mean position)
#-------------------------------------------------------------------------------
function delta(d::DataF1; shiftx=true)
	x = shiftx ? meanadj(d.x) : d.x[1:end-1]
	return DataF1(x, delta(d.y))
end


#==X-value modifiers
===============================================================================#

#Shifts x-values of a dataset by +/-offset:
#-------------------------------------------------------------------------------
function xshift(d::DataF1, offset::Number)
	return DataF1(d.x.+offset, copy(d.y))
end

#Scales x-values of a dataset by fact:
#-------------------------------------------------------------------------------
function xscale(d::DataF1, fact::Number)
	return DataF1(d.x.*fact, copy(d.y))
end

#-------------------------------------------------------------------------------
function yvsx(y::DataF1, x::DataF1)
	_x = x+0*y
	_y = y+0*x
	@assert(_x.x==_y.x, "xvsy algorithm error: not generating unique x-vector.")
	return DataF1(_x.y, _y.y)
end


#==Differential/integral math
===============================================================================#

#-------------------------------------------------------------------------------
function deriv(d::DataF1; shiftx=true)
	x = shiftx ? meanadj(d.x) : d.x[1:end-1]
	return DataF1(x, delta(d.y)./delta(d.x))
end

#Indefinite integral:
#-------------------------------------------------------------------------------
function iinteg(d::DataF1)
	#meanadj ≜ (vi+(vi+1))/2
	area = meanadj(d.y).*delta(d.x)
	return DataF1(d.x, vcat(zero(eltype(d.y)), cumsum(area)))
end

#Definite integral:
#TODO: add start/stop?
#-------------------------------------------------------------------------------
function integ(d::DataF1)
	#meanadj ≜ (vi+(vi+1))/2
	area = meanadj(d.y).*delta(d.x)
	return sum(area)
end

#==Clip
===============================================================================#

#-------------------------------------------------------------------------------
function clip(d::DataF1{TX,TY}, rng::Limits1D{TX}) where {TX<:Number, TY<:Number}
	validate(d); #Expensive, but might avoid headaches
	ensurenotinverted(rng)
	if length(d) < 1; return d; end;

	xmin = clamp(d.x[1], rng)
	xmax = clamp(d.x[end], rng)
	dx = d.x
	x = Vector{TX}(undef, length(dx))

	id=1
	while dx[id]<xmin
		id+=1
	end
	#Here: dx[id]>=xmin
	i=1
	x[i] = xmin
	if dx[id]>xmin; i+=1; end
	istart = i
	dyoffset = id-i
	while dx[id]<xmax
		x[i] = dx[id]
		id+=1
		i+=1
	end
	if !(xmax==xmin) #not already @ max position
		x[i] = xmax
	end

	resize!(x, i)

	#Copy y-values:
	TYR = typeof(one(promote_type(TX,TY))/2) #TODO: is there better way?
	y = Vector{TYR}(undef, length(x))
	for i in istart:(length(x)-1)
		y[i] = d.y[dyoffset+i]
	end
	#TODO: don't use value().  Interpolate in place instead:
	y[1] = value(d, x=x[1])
	y[end] = value(d, x=x[end])

	return DataF1(x, y)
end
clip(d::DataF1{TX,TY}; xmin=nothing, xmax=nothing) where {TX<:Number, TY<:Number} =
	clip(d, Limits1D{TX}(xmin, xmax))
clip(d::DataF1{TX,TY}, rng::AbstractRange) where {TX<:Number, TY<:Number} =
	clip(d, Limits1D{TX}(rng))


#==Sampling algorithm
===============================================================================#

#-------------------------------------------------------------------------------
function sample(d::DataF1{TX,TY}, x::AbstractRange) where {TX<:Number, TY<:Number}
	validate(d); ensureincreasingx(x); #Expensive, but might avoid headaches
	#TODO: deal with empty d
	if length(x) < 1
		return DataF1(zeros(eltype(x),0), zeros(eltype(d.y),0))
	end
	n = length(x)
	y = Vector{TY}(undef, n)
	x = collect(x) #Need it in this form anyways
	dx = d.x #shortcut
	_dx = dx[1]; dx_ = dx[end]
	_x = x[1]; x_ = x[end]
	_xint = max(_dx, _x) #First intersecting point
	xint_ = min(dx_, x_) #Last intersecting point

	#Disjoint dataset:
	if _x > dx_ || _dx > x_
		return DataF1(collect(x), zeros(eltype(d.y),length(x)))
	end

	i = 1 #index into x/y arrays
	id = 1 #index into dx
	while x[i] < _xint
		y[i] = zero(TY)
		i += 1; #x[i] < _xint and set not disjoint: safe to increment i
	end
	p = pnext = Point2D(d, id)
	while x[i] < xint_ #Intersecting section of x
		while pnext.x <= x[i]
			id += 1 #x[i] < _xint: safe to increment id
			p = pnext; pnext = Point2D(d, id)
		end
		y[i] = interpolate(p, pnext, x=x[i])
		i+=1
	end
	#End of intersecting section (x[i]==xint_):
		while pnext.x < x[i]
			id += 1 #x[i] == xint_ && pnext.x < x[i]: safe to increment id
			p = pnext; pnext = Point2D(d, id)
		end
		y[i] = interpolate(p, pnext, x=x[i])
	while i < n #Get remaining points
		i += 1
		y[i] = zero(TY)
	end
	return DataF1(x,y)
end

#Last line
