using Test
using POMDPs
using POMDPModelTools
using BeliefUpdaters
using POMDPModels
using Random

@testset "belief" begin
    include("test_belief.jl")
end

@testset "kprevobs" begin
    include("test_k_previous_observations_belief.jl")
end
