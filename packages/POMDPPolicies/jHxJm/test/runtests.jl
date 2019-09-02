using Test
using POMDPPolicies
using POMDPs
using BeliefUpdaters
using POMDPSimulators
using POMDPModelTools
using POMDPModels
using Random

@testset "alpha" begin
    include("test_alpha_policy.jl")
end
@testset "function" begin
    include("test_function_policy.jl")
end
@testset "stochastic" begin
    include("test_stochastic_policy.jl")
end
@testset "utility" begin
    include("test_utility_wrapper.jl")
end
@testset "vector" begin
    include("test_vector_policy.jl")
end
@testset "random" begin
    include("test_random_solver.jl")
end
@testset "pretty_printing" begin
    include("test_pretty_printing.jl")
end
