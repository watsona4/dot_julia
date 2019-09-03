module ProperOrthogonalDecomposition
using Statistics
using LinearAlgebra

export  PODBasis,
        POD,
        PODsvd,
        PODsvd!,
        PODeigen,
        PODeigen!,
        modeConvergence,
        modeConvergence!

include("types.jl")
include("convergence.jl")
include("PODsvd.jl")
include("PODeigen.jl")

"""
    POD(X)

Computes the Proper Orthogonal Decomposition of `X`. Returns a PODBasis.

This method is just a thin wrapper around `PODsvd(X)`.
"""
function POD(X; subtractmean::Bool = false)
    PODsvd(X, subtractmean = subtractmean)
end

"""
    POD(X, W)

Computes the Proper Orthogonal Decomposition of `X` with weights `W`. Returns a PODBasis.

This method is just a thin wrapper around `PODsvd(X)`.
"""
function POD(X, W; subtractmean::Bool = false)
    PODsvd(X, W, subtractmean = subtractmean)
end


end # module
