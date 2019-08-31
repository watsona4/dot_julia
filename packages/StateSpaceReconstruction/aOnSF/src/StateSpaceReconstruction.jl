__precompile__(true)

module StateSpaceReconstruction

using Reexport
using StaticArrays
using Simplices: even_sampling_rules
using LinearAlgebra

include("GroupSlices.jl")

include("embedding/Embeddings.jl")
include("partitioning/Partitioning.jl")

export embed

end # module
