using Test, BlockDiagonalFactors
using LinearAlgebra, SparseArrays, SuiteSparse

@testset "Testing BlockDiagonalFactors" begin
    @testset "full" begin
        A = rand(3, 3) + I
        B = rand(4, 4) + I
        C = rand(5, 5) + I
        Ms = [A, B, C]
        indices = [1, 1, 2, 1, 3, 1, 3, 2, 1]
        BDF = factorize(Ms, indices)
        @test BDF isa BlockFactors
        m = BDF.m
        n = BDF.n
        BDM = Matrix(blockdiag(map(sparse, Ms[indices])...))
        @test (m,n) == size(BDM)
        b = rand(m)
        x_BDM = BDM \ b
        @testset "backslash" begin
            x_BDF = BDF \ b
            @test x_BDF ≈ x_BDM
            x_BDF = BDF \ (im*b)
            @test x_BDF ≈ (im*x_BDM)
        end
        @testset "ldiv!(A, b)" begin
            x_BDF2 = copy(b)
            ldiv!(BDF, x_BDF2)
            @test x_BDF2 ≈ x_BDM
        end
        @testset "ldiv!(x, A, b)" begin
            x_BDF3 = similar(b)
            ldiv!(x_BDF3, BDF, b)
            @test x_BDF3 ≈ x_BDM
        end
        @testset "adjoint" begin
            @test (x_BDM' * (BDF \ b)) ≈ (b' * (BDF' \ x_BDM))'
        end
    end
    @testset "sparse" begin
        A = sprand(10, 10, 0.5) + I
        B = sprand(20, 20, 0.5) + I
        C = sprand(30, 30, 0.5) + I
        Ms = [A, B, C]
        indices = [1, 1, 2, 1, 3, 1, 3, 2, 1]
        BDF = factorize(Ms, indices)
        @test BDF isa SparseBlockFactors
        m = BDF.m
        n = BDF.n
        BDM = blockdiag(Ms[indices]...)
        @test (m,n) == size(BDM)
        b = rand(m)
        x_BDM = BDM \ b
        @testset "backslash" begin
            x_BDF = BDF \ b
            @test x_BDF ≈ x_BDM
            x_BDF = BDF \ (im*b)
            @test x_BDF ≈ (im*x_BDM)
        end
        @testset "ldiv!(A, b)" begin
            x_BDF2 = copy(b)
            ldiv!(BDF, x_BDF2)
            @test x_BDF2 ≈ x_BDM
        end
        @testset "ldiv!(x, A, b)" begin
            x_BDF3 = similar(b)
            ldiv!(x_BDF3, BDF, b)
            @test x_BDF3 ≈ x_BDM
        end
        @testset "adjoint" begin
            @test (x_BDM' * (BDF \ b)) ≈ (b' * (BDF' \ x_BDM))'
        end
    end
end