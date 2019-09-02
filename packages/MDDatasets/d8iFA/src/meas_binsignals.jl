#MDDatasets: Measure binary signals
#-------------------------------------------------------------------------------
#=NOTE:
 - Many functions make use of "cross" functions.
 - Naming assumes x-values are "time".
=#


#==Helper functions
===============================================================================#

function _buildckvector(ctx::String, tstart::Real, tstop::Real, tsample::Real)
	if isinf(tstart)
		msg = "$ctx: Must specify finite clock start time."
		throw(ArgumentError(msg))
	end

	return collect(tstart:tsample:tstop)
end


#==Main functions
===============================================================================#

#measdelay: Measure delay between crossing events of two signals:
#-------------------------------------------------------------------------------
function measdelay(dref::DataF1, dmain::DataF1; nmax::Integer=0,
	tstart_ref::Real=-Inf, tstart_main::Real=-Inf,
	xing_ref::CrossType=CrossType(), xing_main::CrossType=CrossType())

	xref = xcross(dref, nmax=nmax, xstart=tstart_ref, allow=xing_ref)
	xmain = xcross(dmain, nmax=nmax, xstart=tstart_main, allow=xing_main)
	npts = min(length(xref), length(xmain))
	delay = xmain.y[1:npts] - xref.y[1:npts]
	x = xref.x[1:npts]
	return DataF1(x, delay)
end
function measdelay(::DS{:event}, dref::DataF1, dmain::DataF1, args...; kwargs...)
	d = measdelay(dref, dmain, args...;kwargs...)
	return DataF1(collect(1:length(d.x)), d.y)
end

#measck2q: Measure clock-to-Q delay
#-------------------------------------------------------------------------------

#=_measck2q: Core algorithm to measure clock-to-Q delay
Inputs
   delaymin: Minimum circuit delay used to align clock & q edges
=#
function _measck2q(xingck::Vector, xingq::Vector, delaymin::Real)
	xq = copy(xingq) .- delaymin
	qlen = length(xq) #Maximum # of q-events
	x = copy(xingq) #Allocate space for delay starts
	Δ = copy(xingq) #Allocate space for delays
	cklen = length(xingck)
	npts = 0
	stop = false


	if qlen < 1 || cklen < 2 #Need to know if q is between 2 ck events
		xt = eltype(x)
		return DataF1(Vector{xt}(), Vector{xt}())
	end

	iq = 1
	ick = 1
	xqi = xq[iq]
	xcki = xingck[ick]
	xcki1 = xingck[ick+1]
	while xcki > xqi #Find first q event after first ck event.
		iq += 1
		xqi = xq[iq]
	end

	while iq <= qlen
		xqi = xq[iq]
		#Find clock triggering q event:
		while xcki1 <= xqi
			ick +=1
			if ick < cklen
				xcki = xingck[ick]
				xcki1 = xingck[ick+1]
			else #Not sure if this xqi corresponds to xcki
				stop = true
				break
			end
		end
		if stop; break; end

		#Compute delay (re-insert removed minimum delay):
		npts += 1
		x[npts] = xcki
		Δ[npts] = xqi - xcki + delaymin

		#Consider next q transition:
		iq += 1
	end

	return DataF1(x[1:npts], Δ[1:npts])
end

#=Measure clock-to-Q delay with non-ideal clock.
Inputs
   delaymin: Minimum circuit delay used to align clock & q edges
             Needed when delay is larger than time between ck events.
=#
function measck2q(ck::DataF1, q::DataF1; delaymin::Real=0,
	tstart_ck::Real=-Inf, tstart_q::Real=-Inf,
	xing_ck::CrossType=CrossType(), xing_q::CrossType=CrossType())

	xingck = xcross(ck, xstart=tstart_ck, allow=xing_ck)
	xingq = xcross(q, xstart=tstart_q, allow=xing_q)
	return _measck2q(xingck.x, xingq.x, delaymin)
end
#Measure clock-to-Q delay an ideal sampling clock (tsample).
function measck2q(q::DataF1, tsample::Real; delaymin::Real=0,
	tstart_ck::Real=-Inf, tstart_q::Real=-Inf,
	xing_q::CrossType=CrossType())

	xingck = _buildckvector("measck2q", tstart_ck, (q.x[end]+tsample), tsample)
	xingq = xcross(q, xstart=tstart_q, allow=xing_q)
	return _measck2q(xingck, xingq.x, delaymin)
end

#Measure rise/fall times of a signal
#-------------------------------------------------------------------------------
function measedgewidth(sig::DataF1, tstart::Real, thresh1::Real, thresh2::Real, cross::CrossType)
	x1 = xveccross(sig-thresh1, 0, tstart, cross)
	tstart = x1[1]
	x2 = xveccross(sig-thresh2, 0, tstart, cross)
	_inf = convert(eltype(x1), Inf)

	n1 = length(x1)
	n2 = length(x2)
	y = similar(x1)

	i2 = 1
	x2i = x2[i2]
	for i in 1:n1
		x1i = x1[i]
		while x2i < x1i
			if i2 <= n2
				x2i = x2[i2]
				i2 += 1
			else
				x2i = _inf
			end
		end

		y[i] = x2i - x1i
	end
	#Clamp rise events that failed to cross thresh2:
	for i in 1:(n1-1)
		Δ = x1[i+1] - x1[i]
		if Δ < y[i]
			y[i] = Δ
		end
	end
	#Remove last point if infinite:
	if isinf(y[end])
		n1 -= 1
		resize!(x1, n1)
		resize!(y, n1)
	end
	return DataF1(x1, y)
end

function _measrise(sig::DataF1, tstart::Real, lthresh::Real, hthresh::Real)
	return measedgewidth(sig, tstart, lthresh, hthresh, CrossType(:rise))
end

_measrise(sig::DataF1, tstart::Real, lthresh::Real, hthresh) =
	throw("measrise: Must provide a real value for hthresh")
_measrise(sig::DataF1, tstart::Real, lthresh, hthresh::Real) =
	throw("measrise: Must provide a real value for lthresh")
measrise(sig::DataF1; tstart::Real=-Inf, lthresh=nothing, hthresh=nothing) =
	_measrise(sig, tstart, lthresh, hthresh)

function _measfall(sig::DataF1, tstart::Real, lthresh::Real, hthresh::Real)
	return measedgewidth(sig, tstart, hthresh, lthresh, CrossType(:fall))
end

_measfall(sig::DataF1, tstart::Real, lthresh::Real, hthresh) =
	throw("measrise: Must provide a real value for hthresh")
_measfall(sig::DataF1, tstart::Real, lthresh, hthresh::Real) =
	throw("measrise: Must provide a real value for lthresh")
measfall(sig::DataF1; tstart::Real=-Inf, lthresh=nothing, hthresh=nothing) =
	_measfall(sig, tstart, lthresh, hthresh)


#measskew: Measure skew statistics of a signal
#-------------------------------------------------------------------------------
function _getskewstats(Δr::DataMD, Δf::DataMD)
	μΔr = mean(Δr)
	μΔf = mean(Δf)
	μΔ = (μΔr + μΔf) / 2
	Δmax = max(maximum(Δr), maximum(Δf))
	Δmin = min(minimum(Δr), minimum(Δf))

	#Use ASCII symbols to avoid issues with UTF8:
	return Dict{Symbol, Any}(
		:mean_delrise => μΔr,
		:min_delrise => minimum(Δr),
		:max_delrise => maximum(Δr),
		:mean_delfall => μΔf,
		:min_delfall => minimum(Δf),
		:max_delfall => maximum(Δf),
		:mean_del => μΔ,
		:mean_skew => μΔf-μΔr,
		:max_skew => Δmax - Δmin,
		:std_delrise => std(Δr),
		:std_delfall => std(Δf),
	)
end

#Measure delay skew between a signal and its reference
#returns various statistics.
function measskew(ref::DataMD, sig::DataMD;
	tstart_ref=-Inf, tstart_sig=-Inf)
	xrise = CrossType(:rise)
	xfall = CrossType(:fall)

	Δr = measdelay(ref, sig, tstart_ref=tstart_ref, tstart_main=tstart_sig,
		xing_ref=xrise, xing_main=xrise)
	Δf = measdelay(ref, sig, tstart_ref=tstart_ref, tstart_main=tstart_sig,
		xing_ref=xfall, xing_main=xfall)
	return _getskewstats(Δr, Δf)
end

#Last line
