using Test

using MarkovChains
@testset "poisson_trunc" begin
    λ = 20.0
    tol = 1e-6
    ltp, rtp, probs = poisson_trunc_point(λ, tol)
    @test ltp == 3
    @test rtp == 45
    @test abs(1.0 - sum(probs)) < tol
    λ = 400.0
    ltp, rtp, probs = poisson_trunc_point(λ, tol)
    @test ltp == 306
    @test rtp == 502
    @test abs(1.0 - sum(probs)) < tol
end
