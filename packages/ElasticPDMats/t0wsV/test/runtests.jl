using ElasticPDMats, PDMats, LinearAlgebra
using Test

@testset "PDMat Tests" begin
    a = rand(10, 10); m = a*a';
    epdmat = ElasticPDMat(m, capacity = 2000);
    test_pdmat(epdmat, m, verbose = 0)
end

@testset "append!" begin
    a = rand(10, 10); m = a*a';
    epdmat = ElasticPDMat(m[1:9, 1:9])
    append!(epdmat, m[:, 10])
    @test cholesky(m).U ≈ view(epdmat.chol).U

    epdmat = ElasticPDMat(m[1:6, 1:6])
    append!(epdmat, m[:, 7:10])
    @test cholesky(m).U ≈ view(epdmat.chol).U

    epdmat = ElasticPDMat(m[1:6, 1:6], capacity = 6, stepsize = 6)
    append!(epdmat, m[:, 7:10])
    @test epdmat.mat.m.capacity[1] == epdmat.chol.capacity == 
        size(epdmat.mat.m.data, 1) == size(epdmat.chol.c.factors, 1) == 12
    @test cholesky(m).U ≈ view(epdmat.chol).U
end

@testset "deleteat!" begin
    a = rand(10, 10); m = a*a';
    epdmat = ElasticPDMat(m)
    deleteat!(epdmat, 3)
    m2 = m[[1:2; 4:10], [1:2; 4:10]]
    @test cholesky(m2).U ≈ view(epdmat.chol).U

    a = rand(10, 10); m = a*a';
    epdmat = ElasticPDMat(m)
    deleteat!(epdmat, [3, 8, 7])
    m2 = m[[1:2; 4:6; 9:10], [1:2; 4:6; 9:10]]
    @test cholesky(m2).U ≈ view(epdmat.chol).U
end

@testset "util" begin
    a = rand(10, 10); m = a*a';
    epdmat = ElasticPDMat(m, capacity = 100, stepsize = 50)
    epdmat2 = ElasticPDMat(m, cholesky(m), capacity = 100, stepsize = 50)
    epdmat3 = ElasticPDMat()
    @test epdmat3.mat.m.capacity[1] == epdmat3.chol.capacity == epdmat3.mat.m.stepsize[1] == epdmat3.chol.stepsize == 10^3
    @test epdmat.mat.m.data == epdmat2.mat.m.data
    @test epdmat.chol.c.factors == epdmat2.chol.c.factors
    @test size(epdmat.mat) == (10, 10)
    setstepsize!(epdmat, 100)
    @test epdmat.mat.m.stepsize[1] == epdmat.chol.stepsize == 100
    setcapacity!(epdmat, 20)
    @test epdmat.mat.m.capacity[1] == epdmat.chol.capacity == 20
    @test size(epdmat.mat.m.data) == size(epdmat.chol.c.factors) == (20, 20)
    @test view(epdmat.mat)[:] == m[:]
    @test view(epdmat.chol).U == cholesky(m).U
end
