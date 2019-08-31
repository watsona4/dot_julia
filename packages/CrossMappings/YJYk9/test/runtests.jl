if lowercase(get(ENV, "CI", "false")) == "true"
    include("install_dependencies.jl")
end

using CrossMappings
using Test
using StatsBase
using Distances
using NearestNeighbors
using TimeseriesSurrogates
using StateSpaceReconstruction

include("crossmapping.jl")
include("convergentcrossmapping.jl")
