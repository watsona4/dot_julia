module ReinforcementLearningEnvironmentDiscrete
using ReinforcementLearningBase, SparseArrays, POMDPs, POMDPModels, Random, LinearAlgebra
import StatsBase: sample, wsample
import GR: imshow
import ReinforcementLearningBase: interact!, getstate, reset!, plotenv, actionspace

include("mdp.jl")
include("randommdp.jl")
include("cliffwalking.jl")
include("maze.jl")
include("pomdps.jl") 

export MDP, POMDPEnv, MDPEnv, DiscreteMaze, treeMDP, DetMDP, DetTreeMDP,
DetTreeMDPwithinrew, StochMDP, StochTreeMDP, AbsorbingDetMDP, CliffWalking

end # module
