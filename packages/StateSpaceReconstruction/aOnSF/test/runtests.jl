if lowercase(get(ENV, "CI", "false")) == "true"
    include("install_dependencies.jl")
end


using StateSpaceReconstruction
using Statistics: std
using LinearAlgebra
using Test

if lowercase(get(ENV, "CI", "false")) == "true"
    include("install_dependencies.jl")
end

include("embeddingtests.jl")
include("partitiontests.jl")
