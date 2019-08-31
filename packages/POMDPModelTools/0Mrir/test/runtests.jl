using POMDPModelTools
using POMDPs
using POMDPModels
using Random
using Test
using Pkg
using POMDPSimulators
using POMDPPolicies
import Distributions.Categorical
using SparseArrays

@testset "ordered" begin
    include("test_ordered_spaces.jl")
end

# require POMDPModels
@testset "genbeliefmdp" begin
    include("test_generative_belief_mdp.jl")
end
@testset "implement" begin
    include("test_implementations.jl")
end
@testset "weightediter" begin
    include("test_weighted_iteration.jl")
end
@testset "sparsecat" begin
    include("test_sparse_cat.jl")
end
@testset "bool" begin
    include("test_bool.jl")
end
@testset "deterministic" begin
    include("test_deterministic.jl")
end
@testset "uniform" begin
    include("test_uniform.jl")
end
@testset "terminalstate" begin
    include("test_terminal_state.jl")
end

# require POMDPModels
@testset "info" begin
    include("test_info.jl")
end
@testset "obsweight" begin
    include("test_obs_weight.jl")
end

# require DiscreteValueIteration
@testset "visolve" begin
    POMDPs.add_registry()
    Pkg.add("DiscreteValueIteration")
    using DiscreteValueIteration
    include("test_fully_observable_pomdp.jl")
    include("test_underlying_mdp.jl")
end

@testset "vis" begin
    include("test_visualization.jl")
end

@testset "evaluation" begin
    include("test_evaluation.jl")
end

@testset "pretty printing" begin
    include("test_pretty_printing.jl")
end

@testset "sparse tabular" begin
    include("test_tabular.jl")
end