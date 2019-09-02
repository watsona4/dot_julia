using Test

using MarkovChains
@testset "inftime_solve" begin
@testset "acyclic1" begin
    chain = ContMarkovChain()
    n1 = add_state!(chain)
    n2 = add_state!(chain)
    n3 = add_state!(chain)
    add_transition!(chain, n1, n2, 2.0)
    add_transition!(chain, n2, n3, 4.0)
    init_prob = fill(0.0, state_count(chain))
    init_prob[1] = 1.0
    res = inftime_solve(chain, init_prob)
    cumtime = collect(map(state -> state_cumtime(res, state), n1:n3))
    @test cumtime[n1] ≈ 0.5
    @test cumtime[n2] ≈ 0.25
    @test cumtime[n3] ≈ Inf
    prob = collect(map(state -> state_prob(res, state), n1:n3))
    @test prob[n1] ≈ 0
    @test prob[n2] ≈ 0
    @test prob[n3] ≈ 1

    @test mean_time_to_absorption(chain, init_prob) == 0.75
end
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
    Q = trans_rate_matrix(chain)
    init_prob = fill(0.0, state_count(chain))
    init_prob[1] = 0.1
    init_prob[2] = 0.9
    res = inftime_solve(chain, init_prob)
    cumtime = collect(map(state -> state_cumtime(res, state), n0:n3))
    for t in cumtime
        @test t == Inf
    end
    prob = collect(map(state -> state_prob(res, state), n0:n3))
    @test prob ≈ [0.375, 0.375, 0.1875, 0.0625]
end
@testset "multiple_comps" begin
    chain = ContMarkovChain()
    t0 = add_state!(chain)
    t1 = add_state!(chain)
    t2 = add_state!(chain)
    m1 = add_state!(chain)
    m2 = add_state!(chain)
    n1 = add_state!(chain)
    n2 = add_state!(chain)
    add_transition!(chain, t0, t1, 1.0)
    add_transition!(chain, t1, t2, 1.0)
    add_transition!(chain, t2, t1, 2.0)
    add_transition!(chain, t1, m1, 1.0)
    add_transition!(chain, t2, n1, 3.0)
    add_transition!(chain, m1, m2, 2.0)
    add_transition!(chain, m2, m1, 1.0)
    add_transition!(chain, n1, n2, 2.0)
    add_transition!(chain, n2, n1, 1.0)
    init_prob = fill(0.0, state_count(chain))
    init_prob[1] = 1.0
    res = inftime_solve(chain, init_prob)
    cumtime = collect(map(state -> state_cumtime(res, state), t0:n2))
    for t in cumtime[[m1, m2, n1, n2]]
        @test t == Inf
    end
    for t in cumtime[[t0, t1, t2]]
        @test t > 0
    end
    prob = collect(map(state -> state_prob(res, state), t0:n2))
    for p in prob[[t0, t1, t2]]
        @test p == 0.0
    end
    for p in prob[[m1, m2, n1, n2]]
        @test p > 0
    end

    @test isinf(mean_time_to_absorption(chain, init_prob))
end
using SparseArrays
@testset "multiple_comps_init_bottom" begin
    chain = ContMarkovChain()
    t0 = add_state!(chain)
    t1 = add_state!(chain)
    t2 = add_state!(chain)
    m1 = add_state!(chain)
    m2 = add_state!(chain)
    n1 = add_state!(chain)
    n2 = add_state!(chain)
    add_transition!(chain, t0, t1, 1.0)
    add_transition!(chain, t1, t2, 1.0)
    add_transition!(chain, t2, t1, 2.0)
    add_transition!(chain, t1, m1, 1.0)
    add_transition!(chain, t2, n1, 3.0)
    add_transition!(chain, m1, m2, 2.0)
    add_transition!(chain, m2, m1, 1.0)
    add_transition!(chain, n1, n2, 2.0)
    add_transition!(chain, n2, n1, 1.0)
    init_prob = sparsevec([n2, n1, m1], [0.7, 0.2, 0.1])
    res = inftime_solve(chain, init_prob)
    cumtime = collect(map(state -> state_cumtime(res, state), t0:n2))
    for t in cumtime[[m1, m2, n1, n2]]
        @test t == Inf
    end
    for t in cumtime[[t0, t1, t2]]
        @test t == 0.0
    end
    prob = collect(map(state -> state_prob(res, state), t0:n2))
    for p in prob[[t0, t1, t2]]
        @test p == 0.0
    end
    @test prob[n1] == 1.0 / 3.0 * 0.9
    @test prob[n2] == 2.0 / 3.0 * 0.9
    @test prob[m1] == 1.0 / 3.0 * 0.1
    @test prob[m2] == 2.0 / 3.0 * 0.1
end
@testset "one_state" begin
    chain = ContMarkovChain()
    t0 = add_state!(chain)
    init_prob = sparsevec([t0], [1.0])
    res = inftime_solve(chain, init_prob)
    @test state_cumtime(res, t0) == Inf
    @test state_prob(res, t0) == 1.0
    @test mean_time_to_absorption(chain, init_prob) == 0.0
end
@testset "zero_state" begin
    chain = ContMarkovChain()
    init_prob = sparsevec([], [])
    res = inftime_solve(chain, init_prob)
end

end
