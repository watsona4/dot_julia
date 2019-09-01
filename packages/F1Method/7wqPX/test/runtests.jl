
using Test, F1Method

using LinearAlgebra, DiffEqBase, ForwardDiff

# Set up:
# - overload `SteadyStateProblem` constructor
# - overload `solve` function
# - define solver algorithm (basic Newton here)
# - define type for that algorithm (here `MyAlg`)
include("simple_setup.jl")

@testset "quasi-Rosenbrock derivative" begin
    include("rosenbrock.jl")
end

