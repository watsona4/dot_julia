module HilbertSchmidtIndependenceCriterion

	using StatsFuns, Distances

  # load Base modules
  using Statistics, LinearAlgebra

	# includes
	include("common.jl")
	include("gammaHSIC.jl")

	# function exports
	export gammaHSIC, estimateKernelSize, rbfDotProduct

end # module
