__precompile__(true)

module PerronFrobenius

using Reexport
@reexport using StateSpaceReconstruction
using StateSpaceReconstruction: GroupSlices
using StateSpaceReconstruction: Embeddings
import StateSpaceReconstruction.Embeddings.AbstractEmbedding

using Distributed
using SharedArrays
using StaticArrays
using SparseArrays
using InplaceOps
using RecipesBase
using Printf
using Documenter
using LinearAlgebra

import Parameters:
            @with_kw,
            @unpack

using Simplices:
            subsample_coeffs,
            simplexintersection

# Abstract estimator type
abstract type TransferOperatorEstimator end

include("TransferOperator.jl")
include("invariantmeasure/InvariantMeasure.jl")


export
    # Transfer operator types
    AbstractTransferOperator,
	AbstractTriangulationTransferOperator,
    ApproxSimplexTransferOperator,
    ExactSimplexTransferOperator,
    RectangularBinningTransferOperator,

    # Methods on transfer operator types
    is_markov,
    is_almost_markov,
    InvariantDistribution, left_eigenvector, invariantmeasure,

	# Stuff needed for the estimators
	organize_bin_labels, BinVisits,

    # Transfer operator estimators
    transferoperator_binvisits,
    transferoperator_grid,
    transferoperator_triang,
    transferoperator_approx,
    transferoperator_exact,
    transferoperator_exact_p

end
