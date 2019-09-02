using Test

using MarkovChains
@testset "solve" begin
    @testset "irreducible1" begin
        chain = ContMarkovChain()
        n0 = add_state!(chain)
        n1 = add_state!(chain)
        n2 = add_state!(chain)
        n3 = add_state!(chain)
        add_transition!(chain, n0, n1, 1.0)
        add_transition!(chain, n1, n2, 1.0)
        add_transition!(chain, n2, n3, 1.0)
        add_transition!(chain, n3, n2, 3.0)
        add_transition!(chain, n2, n1, 2.0)
        add_transition!(chain, n1, n0, 1.0)
        init_prob = [0.1, 0.9, 0.0, 0.0]
        ts_sol = solve(chain, init_prob, 0.0)
        @test ts_sol.prob ≈ [0.1, 0.9, 0.0, 0.0]
        @test ts_sol.cumtime ≈ [0.0, 0.0, 0.0, 0.0]

        ss_sol = solve(chain, init_prob, Inf)
        @test ss_sol.prob ≈ [0.375, 0.375, 0.1875, 0.0625]
        @test ss_sol.cumtime == [Inf, Inf, Inf, Inf]
    end
    @testset "acyclic1" begin
    chain = ContMarkovChain()
    n1 = add_state!(chain)
    n2 = add_state!(chain)
    n3 = add_state!(chain)
    add_transition!(chain, n1, n2, 2.0)
    add_transition!(chain, n2, n3, 4.0)
    init_prob = [1.0, 0.0, 0.0]
    ts_sol = solve(chain, init_prob, 0.0)
    @test ts_sol.prob ≈ [1.0, 0.0, 0.0]

    ts_sol = solve(chain, init_prob, 1.0)
    @test state_prob(ts_sol, 1) < 1.0
    @test state_prob(ts_sol, 2) > 0.0
    @test state_prob(ts_sol, 3) > 0.0

    ss_sol = solve(chain, init_prob, Inf)
    @test state_cumtime(ss_sol, 1) == 0.5
    @test state_cumtime(ss_sol, 2) == 0.25
    @test state_cumtime(ss_sol, 3) == Inf
    @test ss_sol.prob ≈ [0.0, 0.0, 1.0]

    end
end
