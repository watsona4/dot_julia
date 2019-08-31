module CausalityToolsBase
	import ChaosTools: non0hist
	import StaticArrays: MVector, SVector
	import DelayEmbeddings: AbstractDataset, Dataset

	include("discretization/discretization.jl")
	include("reconstruction/custom_reconstruction.jl")
	include("dimension_estimation.jl")
	include("simplex_intersections.jl")
	
	include("kerneldensity/kerneldensity.jl")
	include("mutual_information/mutualinformation.jl") # must be loaded after kerneldensity

end # module

"""
	CausalityToolsBase

A lightweight module containing data structures and algorithms used throughout the 
CausalityTools ecosystem.
"""