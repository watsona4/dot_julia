using LinearAlgebra
using SparseArrays
using NetworkLearning
using LightGraphs: Graph, add_edge! 
using SimpleWeightedGraphs: SimpleWeightedGraph
using LearnBase: ObsDim, ObsDimension
using Statistics: mean
using Test
using Future: copy!
using DelimitedFiles: readdlm

# Test components
include("t_components.jl")
Test.@testset "Network Learning (various components)" begin 
	t_components(); 
end

# Test observation-based learning
include("t_observation_networklearner.jl")
Test.@testset "Network Learning (observation-based)" begin 
	t_observation_networklearner(); 
end

# Test entity-based learning
include("t_entity_networklearner.jl")
Test.@testset "Network Learning (entity-based)" begin 
	t_entity_networklearner(); 
end
