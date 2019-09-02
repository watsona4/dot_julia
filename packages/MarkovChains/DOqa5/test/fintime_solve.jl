using Test
using SparseArrays
using MarkovChains
using Base.MathConstants

@testset "fintime_solve" begin
    @testset "irreducible1_prob" begin
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
        init_prob = sparsevec([1, 2], [0.1, 0.9])
        res = fintime_solve_prob(chain, init_prob, 0.0).prob
        @test res ≈ [0.1, 0.9, 0.0, 0.0]

        res = fintime_solve_prob(chain, init_prob, 20.0).prob
        @test res ≈ [0.375, 0.375, 0.1875, 0.0625]
    end
    @testset "acyclic1" begin
    chain = ContMarkovChain()
    n1 = add_state!(chain)
    n2 = add_state!(chain)
    n3 = add_state!(chain)
    add_transition!(chain, n1, n2, 2.0)
    add_transition!(chain, n2, n3, 4.0)
    init_prob = sparsevec([1], [1.0])
    res = fintime_solve_cum(chain, init_prob, 100)
    cumtime = collect(map(state -> state_cumtime(res, state), n1:n3))
    @test cumtime[n1] ≈ 0.5
    @test cumtime[n2] ≈ 0.25

    res = solve(chain, init_prob, 1.0)
    @test state_prob(res, n1) ≈ e ^ (-2.0 * 1.0)

    res = solve(chain, init_prob, 4.0)
    @test abs(state_prob(res, n1) - e ^ (-2.0 * 4.0)) < 1e-6
    end

    @testset "two_state_cum" begin
    chain = ContMarkovChain()
    n1 = add_state!(chain)
    n2 = add_state!(chain)
    add_transition!(chain, n1, n2, 2.0)
    add_transition!(chain, n2, n1, 4.0)
    init_prob = sparsevec([1, 2], [0.2, 0.8])

    t = 10.0
    sol = solve(chain, init_prob, t)
    t1 = state_cumtime(sol, n1)
    t2 = state_cumtime(sol, n2)
    @test t1 + t2 ≈ t
    end
end
