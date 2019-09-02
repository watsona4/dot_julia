#MDDatasets: Tools to store/manipulate multi-dimensional data
#-------------------------------------------------------------------------------
__precompile__(true)
#=
TAGS:
	#WANTCONST, HIDEWARN_0.7
=#

module MDDatasets

import Base: values
using Statistics

#==Suggested scalar data types
	-Use concrete types of the largest size natively supported by processor
   -Eventually should move to 128-bit values, etc.==#
const DataFloat = Float64
const DataInt = Int64
const DataComplex = Complex{Float64}
#==NOTES:
Don't use Int.  If this is like c, "Int" represents the "native" integer
size/type.  That might not be the same as the largest integer that can be
handled with reasonable efficiency

No reason to have an alias for Bool.  Probably best to keep the default
representation.==#

#Type used to dispatch on a symbol & minimize namespace pollution:
#-------------------------------------------------------------------------------
struct DS{Symbol}; end; #Dispatchable symbol
DS(v::Symbol) = DS{v}()

#-------------------------------------------------------------------------------
include("functions.jl")
include("math.jl")
include("physics.jl")
include("arrays.jl")
include("base.jl")
include("datahr.jl")
include("datars.jl")
include("datasetop.jl")
include("meas_cross.jl")
include("meas_cksignals.jl")
include("meas_binsignals.jl")
include("broadcast.jl")
include("broadcast_datahr.jl")
include("broadcast_datars.jl")
include("datasetop_reg.jl")
include("measinterface.jl")
include("show.jl")

#==TODO: Watch out for value() being exported by multiple modules...
Maybe it can be defined in "Units"
==#

#Data types:
#-------------------------------------------------------------------------------
export DataFloat, DataInt, DataComplex
export DataMD #Prefered abstraction for high-level functions
export PSweep #Parameter sweep
export Index #A way to identify parameters as array indicies
export DataFloat, DataInt, DataComplex, DataF1 #Leaf data types
export DataHR, DataRS

#Support functions:
#-------------------------------------------------------------------------------
export ensure

#Scalar operations:
#-------------------------------------------------------------------------------
export sanitize #Clamp down infinite values & substitute NaNs

#Accessor functions:
#-------------------------------------------------------------------------------
export value #High-collision WARNING: other modules probably want to export "value".
export sweep #Access values from a particular parameter sweep.
export sweeps #Get the list of parameter sweeps in DataHR.
export subscripts #Provides subscripts iterator to access each element in DataHR.
export getsubarray
export coordinates #Get parameter sweep coordinates corresponding to given subscripts.
export parameter #Get parameter values for a particular sweep.

#Basic dataset operations:
#-------------------------------------------------------------------------------
export xval #Gets a dataset with all the x-values as the y-values
#value(ds, x=value) (already exported): get y-value @ given x.
export clip #clips a dataset within an xrange
export sample #Samples a dataset
export delta, xshift, xscale
export yvsx
export deriv, iinteg #derivative, definite integral, indefinite integral
export integ, xmin, xmax

#Cross operations:
#-------------------------------------------------------------------------------
#==API
NOTE: using "{Event}" for type stability (I hope)

Returns x-values of d1 (up-to nmax) when d1 crosses 0 (nmax=0: get all crossings):
xcross(d1, nmax; xstart, allow::CrossType)
xcross(Event, d1, nmax; xstart, allow::CrossType)

Returns y-values of d2 (up-to nmax) when when d1 crosses d2 (nmax=0: get all crossings):
ycross(d1, d2, nmax; xstart, allow::CrossType)
ycross(Event, d1, d2, nmax; xstart, allow::CrossType)

Returns scalar x-value of d1 on n-th zero-crossing:
xcross1(d1; n, xstart, allow::CrossType)
xcross1(Event, d1; n, xstart, allow::CrossType)

Returns scalar y-value of d1 on n-th crossing of d1 & d2:
ycross1(d1, d2; n, xstart, allow::CrossType)
ycross1(Event, d1, d2; n, xstart, allow::CrossType)

Resultant x-values are x-values of d1 @ crossings:
(x/y)cross

Resultant x-values corresponds to number of current crossing event (1, 2, ..., n):
(x/y)cross{Event}
==#
export Event #Identifies result as having event count in x-axis
export CrossType #To filter out unwanted crossings
export xcross, xcross1 #Measure x @ crossing events
export ycross, ycross1 #Measure y @ crossing events
export measdelay #Measure delay between crossing events of two signals
export measperiod, measfreq, measduty, measckstats
export measck2q, measskew
export measrise, measfall

export meas #Use meas(:MEASTYPE, ...) to minimize namespace pollution.
#==Sample usage:
TODO: Deprecate direct call of x/ycross/1 & measdelay
ON CONDITION: Only if this interface does not mess up type stability.
meas(:xcross, Event, d1)
==#


#==Initialization
===============================================================================#
function __init__()
	show(:HACK_SHOWTOUNFREEZE) #Not sure why show unfreezes dependent modules (those using this one)
	println() #newline
	return
end

end #MDDatasets

#Last line
