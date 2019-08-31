mutable struct TestMDP <: MDP{Bool, Bool} end
mutable struct TestPOMDP <: POMDP{Bool, Bool, Bool} end

let 
    # @test actions(TestMDP()) == (true, false)
    # @test actions(TestPOMDP()) == (true, false)

    a = [1,2,3]
    @test support(a) == a
    @test support((1,2,3)) == (1,2,3)

    # @test states(TestMDP()) == (true, false)
    # @test states(TestPOMDP()) == (true, false)

    # @test observations(TestPOMDP()) == (true, false)
    # @test n_observations(TestPOMDP()) == 2

    # @test stateindex(TestMDP(), 1) == 1
    # @test actionindex(TestMDP(), 2) == 2
    # @test obsindex(TestMDP(), 3) == 3
end

