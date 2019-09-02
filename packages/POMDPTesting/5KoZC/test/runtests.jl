using Test
using POMDPs
using POMDPTesting
using POMDPModelTools

import POMDPs: transition, observation, initialstate_distribution, updater

struct TestPOMDP <: POMDP{Bool, Bool, Bool} end
updater(problem::TestPOMDP) = DiscreteUpdater(problem)
initialstate_distribution(::TestPOMDP) = BoolDistribution(0.0)
transition(p::TestPOMDP, s::Bool, a::Bool) = BoolDistribution(0.5)
observation(p::TestPOMDP, a::Bool, sp::Bool) = BoolDistribution(0.5)
@testset "model" begin
    POMDPTesting.probability_check(TestPOMDP())
end




