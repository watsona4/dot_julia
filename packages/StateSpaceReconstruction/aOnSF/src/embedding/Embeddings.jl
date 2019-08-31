using Reexport
@reexport module Embeddings

using StaticArrays
using Distributions
using Statistics
using NearestNeighbors

include("types.jl")
include("embed.jl")
include("delaunay.jl")
include("invariantize.jl")

# Interface with NearestNeighbors, allowing to create trees from embeddings.
include("nearestneighbors.jl")

end
