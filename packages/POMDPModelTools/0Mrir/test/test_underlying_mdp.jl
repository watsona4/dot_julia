let
    pomdp = TigerPOMDP()

    mdp = UnderlyingMDP(pomdp)

    @test n_states(mdp) == n_states(pomdp)
    @test states(mdp) == states(pomdp)
    s_mdp = rand(MersenneTwister(1), initialstate_distribution(mdp))
    s_pomdp = rand(MersenneTwister(1), initialstate_distribution(pomdp))

    @test s_mdp == s_pomdp

    solver = ValueIterationSolver(max_iterations = 100)
    mdp_policy = solve(solver, mdp)
    pomdp_policy = solve(solver, pomdp)
    @test mdp_policy.util == pomdp_policy.util

    actionindex(mdp, 1)

    # test mdp passthrough
    m = SimpleGridWorld()
    @test UnderlyingMDP(m) === m
end
