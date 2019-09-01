module ForecastEval
#-----------------------------------------------------------
#PURPOSE
#	Colin T. Bowers module for forecast evaluation
#NOTES
#-----------------------------------------------------------

using 	StatsBase,
		Distributions,
		DependentBootstrap

import 	Base.show

export 	DMMethod,
		DMBoot,
		DMHAC,
		DMTest,
		dm,
		RCMethod,
		RCBoot,
		RCTest,
		rc,
		SPAMethod,
		SPABoot,
		SPATest,
		spa,
		MCSMethod,
		MCSBoot,
		MCSBootLowRAM,
		MCSTest,
		mcs


include("hacvariance.jl")
include("pvaluelocal.jl")
include("dm.jl")
include("rc.jl")
include("spa.jl")
include("mcs.jl")
include("mcs_lowRAM.jl")

end #module
