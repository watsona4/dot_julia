# __precompile__()

module SubMatrixSelectionSVD

using LinearAlgebra
using Statistics
using Distributed

export
    smssvd,
    projectionscore,
    projectionscorefiltered

include("projectionscore.jl")
include("smssvdimpl.jl")
include("precompile.jl")
# _precompile_()

end
