

@testset "Transfer operator from triangulations" begin
    # Embeddings
    E = embed([diff(rand(15)) for i = 1:3])
    E_invariant = invariantize(E)

    # Triangulations
    triang = triangulate(E)
    triang_inv = triangulate(E_invariant)

    # Transfer operators from *invariant* triangulations
    TO = transferoperator_triang(triang_inv)
    TO_approx = transferoperator_triang(triang_inv, exact = false, parallel = false)
    TO_approx_rand = transferoperator_triang(triang_inv, exact = false, parallel = false, sample_randomly = true)
    #TO_exact = transferoperator(triang_inv, exact = true, parallel = false)
    #TO_exact_p = transferoperator(triang_inv, exact = true, parallel = true)

    @test typeof(TO) == ApproxSimplexTransferOperator #default = approx
    @test typeof(TO_approx) == ApproxSimplexTransferOperator
    @test typeof(TO_approx_rand) == ApproxSimplexTransferOperator
    #@test typeof(TO_exact) == ExactSimplexTransferOperator
    #@test typeof(TO_exact_p) == ExactSimplexTransferOperator

    #@test all(TO_exact.transfermatrix .== TO_exact_p.transfermatrix)

    # Approximations to intersections
    @test is_markov(TO)
    @test is_markov(TO_approx)
    @test is_markov(TO_approx_rand)
    @test is_almost_markov(TO)
    @test is_almost_markov(TO_approx)
    @test is_almost_markov(TO_approx_rand)

    # Exact intersections

    #@test is_almost_markov(TO_exact)
    #@test is_almost_markov(TO_exact_p)
    #@test is_markov(TO_exact)
    #@test is_markov(TO_exact_p)

    # Transfer operators from regular triangulations *not guaranteed to be invariant*
    TO = transferoperator_triang(triang)
    TO_approx = transferoperator_triang(triang, exact = false, parallel = false)
    TO_approx_rand = transferoperator_triang(triang, exact = false,
					parallel = false, sample_randomly = true)
    #TO_exact = transferoperator(triang, exact = true, parallel = false)
    #TO_exact_p = transferoperator(triang, exact = true, parallel = true)

    @test typeof(TO) == ApproxSimplexTransferOperator #default = approx
    @test typeof(TO_approx) == ApproxSimplexTransferOperator
    @test typeof(TO_approx_rand) == ApproxSimplexTransferOperator
    #@test typeof(TO_exact) == ExactSimplexTransferOperator
    #@test typeof(TO_exact_p) == ExactSimplexTransferOperator
    #@test all(TO_exact.transfermatrix .== TO_exact_p.transfermatrix)

end
