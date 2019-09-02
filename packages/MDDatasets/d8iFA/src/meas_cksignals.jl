#MDDatasets: Measure clock signals
#-------------------------------------------------------------------------------
#=NOTE:
 - Many functions make use of "cross" functions.
 - Naming assumes x-values are "time".
=#


#==
===============================================================================#

#measperiod: Measure period between successive zero-crossings:
#-------------------------------------------------------------------------------
function measperiod(d::DataF1; nmax::Integer=0, tstart::Real=-Inf,
	xing::CrossType=CrossType(), shiftx=true)

	dx = xcross(d, nmax=nmax, xstart=tstart, allow=xing)
	return delta(dx, shiftx=shiftx)
end

#measfreq: Measure 1/period between successive zero-crossings:
#-------------------------------------------------------------------------------
function measfreq(d::DataF1; nmax::Integer=0, tstart::Real=-Inf,
	xing::CrossType=CrossType(), shiftx=true)

	T = measperiod(d, nmax=nmax, tstart=tstart, xing=xing, shiftx=shiftx)
	return DataF1(T.x, 1 ./ T.y)
end

#measduty: Measure duty cycle of a periodic signal @ zero-crossings:
#TODO: Improve: Could break in the presence of noise.
#-------------------------------------------------------------------------------
function measduty(d::DataF1; nmax::Integer=0, tstart::Real=-Inf, shiftx=true)
	xrise1 = xcross1(d, xstart=tstart, allow=CrossType(:rise))
	xrise = xveccross(d, nmax, tstart, CrossType(:rise))
	xfall = xveccross(d, nmax, xrise1, CrossType(:fall))
	#Need 1 more rise to get period
	numpts = min(length(xrise)-1, length(xfall))
	x = shiftx ? meanadj(xrise[1:(numpts+1)]) : xrise[1:numpts]
	duty = similar(xrise, numpts)

	for i in 1:numpts
		T = xrise[i+1]-xrise[i]
		duty[i] = (xfall[i]-xrise[i])/T
	end

	return DataF1(x, duty)
end

#measckstats: Measure clock statistics @ zero-crossings:
#-------------------------------------------------------------------------------
#=NOTE
A bit awkward to implement because broadcast system does not work with this
return type (Dict).  So, to work with sweeps (DataHR/DataRS), we must only
use high-level (broadcastable) functions.  We cannot use functions that
return arbitrary vectors, or tuples, or ...

OR:
We could loop across all sweep dimensions manually....

TODO:
 - Figure out if stats are defined correctly.
 - Should there be a function for relative values vs referenced to an ideal clock?
 - Improve: Could break in the presence of noise.
=#
function measckstats(d::DataMD; tstart=-Inf, tck=nothing)
	if nothing==tck
		msg = "measckstats: Must provide value to tck."
		throw(ArgumentError(msg))
	end
	xrise1 = xcross1(d, xstart=tstart, allow=CrossType(:rise))
	xrise = xcross(Event, d, xstart=tstart, allow=CrossType(:rise))
	xfall = xcross(Event, d, xstart=xrise1, allow=CrossType(:fall))


	#Want to match up rise/fall events:
	maxevent = min(maximum(xval(xrise)-1), maximum(xval(xfall)))
	#TODO: cnovert to fixed-point to avoid roundoff errors?
	xrise = clip(xrise, xmax=maxevent+1)
	xfall = clip(xfall, xmax=maxevent)

	#Cycle-to-cycle jitter:
	period = delta(xrise, shiftx=false)
	jitc2c = std(period)

	#Match up # of events:
	xrise = clip(xrise, xmax=maxevent)

	tph = xfall - xrise
	tpl = period - tph

	duty = tph/period
	dcd = duty-0.5 #Is this off by a factor of 2??

	#Measure mean values, relative to absolute clock:
#-----------
	#Wrap crossings back around first point:
	_tshift = xval(xrise)*tck
	xrise = xrise-_tshift
	xfall = xfall-_tshift

	#Jitter relative to absolute reference:
	jit = std(xrise)

	#Mean rise/fall times:
	μxr = mean(xrise)
	μxf = mean(xfall)

	#Ensure rise happens first for all runs:
	risefirst = μxf>μxr #Probably not needed (see xrise1)
	xfall = xfall+(1-risefirst)*tck #High pulse
	μxf = mean(xfall)

	#Mean pulse high/low values:
	μtph = μxf-μxr
	μtpl = tck - μtph

	#Mean duty cycle values:
	μduty = μtph / tck
	μdcd = μduty-0.5 #Is this off by a factor of 2??

	return Dict{Symbol, Any}(
		:period => tck,
		:jitter => jit,
		:jitter_c2c => jitc2c,

		:std_tph => std(tph),
		:std_tpl => std(tpl),
		:std_duty => std(duty),
		:std_dcd => std(dcd),

		:min_tph => minimum(tph),
		:min_tpl => minimum(tpl),
		:min_duty => minimum(duty),
		:min_dcd => minimum(dcd),

		:max_tph => maximum(tph),
		:max_tpl => maximum(tpl),
		:max_duty => maximum(duty),
		:max_dcd => maximum(dcd),

		#Curretntly from absolute measurements only:
		:mean_tph => μtph,
		:mean_tpl => μtpl,
		:mean_duty => μduty,
		:mean_dcd => μdcd,
	)
end

#Last line
