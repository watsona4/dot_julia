te = [-0.112639 0.124715 0.124715 0.268717 0.124715 0.268717 0.268717 0.046154]
st = SymmetricTensor(reshape(te, (2,2,2)))
Random.seed!(43)
c = cumulants(randn(1000, 20), 4)

@testset "axiliary functions" begin
    @test rep((1,2,3)) == 6
    @test rep((1,2,2)) == 3
    @test rep((1,1,1)) == 1
end

@testset "norm" begin
    @test norm(st) ≈ 0.5273572868359742
    @test norm(st, 1) ≈ 1.339089
    @test norm(st, 2.5) ≈ norm(te, 2.5)
    n = norm(c[2])
    @test n ≈ norm(Array(c[2]))
    @test cnorms(c) ≈ [norm(c[3])/(n^(3/2)), norm(c[4])/(n^2)]
end
