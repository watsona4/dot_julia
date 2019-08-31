if lowercase(get(ENV, "CI", "false")) == "true"
    include("install_dependencies.jl")
end

using Test
using StateSpaceReconstruction
using PerronFrobenius

include("rectangular.jl")
include("invariantmeasure.jl")
include("triangulations.jl")
