let
    mdp = GridWorld()

    pomdp = FullyObservablePOMDP(mdp)

    @test observations(pomdp) == states(pomdp)
    @test n_observations(pomdp) == n_states(pomdp)
    @test statetype(pomdp) == obstype(pomdp)

    @test observations(pomdp) == states(pomdp)
    @test n_observations(pomdp) == n_states(pomdp)
    @test statetype(pomdp) == obstype(pomdp)
    
    s_po = initialstate(pomdp, MersenneTwister(1))
    s_mdp = initialstate(mdp, MersenneTwister(1))
    @test s_po == s_mdp

    solver = ValueIterationSolver(max_iterations = 100)
    mdp_policy = solve(solver, mdp)
    pomdp_policy = solve(solver, pomdp)
    @test mdp_policy.util == pomdp_policy.util
end
