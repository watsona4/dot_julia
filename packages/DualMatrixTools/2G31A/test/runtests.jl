using Test

using DualMatrixTools
using DualNumbers, LinearAlgebra, SparseArrays, SuiteSparse

@testset "Testing DualMatrixTools" begin
    # Chose a size for matrices
    n = 10

    x = randn(n)     # real-valued │
    y = randn(n)     # real-valued ├─ vector
    d = x + ε * y    # dual-valued │

    A = randn(n, n)  # real-valued │
    B = randn(n, n)  # real-valued ├─ matrix
    M = A + ε * B    # dual-valued │

    @testset "Testing full matrices" begin
        @testset "Testing `\\` without factorization" begin
            @test A \ (A * x) ≈ x
            @test M \ (M * x) ≈ x
            @test A \ (A * d) ≈ d
            @test M \ (M * d) ≈ d
            @test A * (A \ x) ≈ x
            @test M * (M \ x) ≈ x
            @test A * (A \ d) ≈ d
            @test M * (M \ d) ≈ d
        end

        @testset "Testing `\\` with factorization" begin
            Af = factorize(A)
            Mf = factorize(M)
            @test Af \ (A * x) ≈ x
            @test Mf \ (M * x) ≈ x
            @test Af \ (A * d) ≈ d
            @test Mf \ (M * d) ≈ d
            @test A * (Af \ x) ≈ x
            @test M * (Mf \ x) ≈ x
            @test A * (Af \ d) ≈ d
            @test M * (Mf \ d) ≈ d
        end
    end

    @testset "Inplace factorization" begin
        Mf1 =factorize(M)
        Mf2 = factorize(M)
        factorize(Mf2, 2M)
        @test Mf2.Af == Mf1.Af
        @test Mf2.B == 2Mf1.B
        factorize(Mf2, 2M, update_factors=true)
        @test Mf2.Af ≠ Mf1.Af
        @test Mf2.B == 2Mf1.B
    end

    @testset "Testing sparse matrices" begin
        spA = sparse(A)  # │
        spB = sparse(B)  # ├─ sparse matrices
        spM = sparse(M)  # │

        @testset "Check that `ε * A` works" begin
            @test spM ≈ spA + ε * spB
        end

        @testset "Check that `\\` works without factorization" begin
            @test spA \ (spA * x) ≈ x
            @test spM \ (spM * x) ≈ x
            @test spA \ (spA * d) ≈ d
            @test spM \ (spM * d) ≈ d
            @test spA * (spA \ x) ≈ x
            @test spM * (spM \ x) ≈ x
            @test spA * (spA \ d) ≈ d
            @test spM * (spM \ d) ≈ d
        end

        @testset "Check that `\\` works with factorization" begin
            spAf = factorize(spA)
            spMf = factorize(spM)
            @test spAf \ (spA * x) ≈ x
            @test spMf \ (spM * x) ≈ x
            @test spAf \ (spA * d) ≈ d
            @test spMf \ (spM * d) ≈ d
            @test spA * (spAf \ x) ≈ x
            @test spM * (spMf \ x) ≈ x
            @test spA * (spAf \ d) ≈ d
            @test spM * (spMf \ d) ≈ d
        end
    end

    # TODO Add tests specific to `lu`, `qr`, `cholesky`, etc.

    @testset "Testing $f" for f in [:adjoint, :transpose]
        spA = sparse(A)  # │
        spB = sparse(B)  # ├─ sparse matrices
        spM = sparse(M)  # │

        # Adjoints / transposes
        x₂ = randn(n)     # real-valued │
        y₂ = randn(n)     # real-valued ├─ vector
        d₂ = x₂ + ε * y₂  # dual-valued │

        @eval begin
            x₂′ = $f($x₂)
            x′ = $f($x)
            d₂′ = $f($d₂)
            d′ = $f($d)
            A′  = $f($A)
            M′  = $f($M)
            spA′  = $f($spA)
            spM′  = $f($spM)
        end

        # Check that `\` works with adjoints
        @testset "Check that `\\` works with $f" begin
            @test (x₂′ * (A \ x)) ≈ (x′ * (A′ \ x₂))
            @test (d₂′ * (M \ d)) ≈ (d′ * (M′ \ d₂))
            @test (x₂′ * (spA \ x)) ≈ (x′ * (spA′ \ x₂))
            @test (d₂′ * (spM \ d)) ≈ (d′ * (spM′ \ d₂))
        end

        # Check that `\` works with adjoints of factorized versions
        Af = factorize(A)
        Mf = factorize(M)
        spAf = factorize(spA)
        spMf = factorize(spM)
        @eval begin
            Af′  = $f($Af)
            Mf′  = $f($Mf)
            spAf′  = $f($spAf)
            spMf′  = $f($spMf)
        end
        @testset "Check that factorized version with $f" begin
            @test (x₂′ * (Af \ x)) ≈ (x′ * (Af′ \ x₂))
            @test (d₂′ * (Mf \ d)) ≈ (d′ * (Mf′ \ d₂))
            @test (x₂′ * (spAf \ x)) ≈ (x′ * (spAf′ \ x₂))
            @test (d₂′ * (spMf \ d)) ≈ (d′ * (spMf′ \ d₂))
        end
    end

    @testset "Testing isapprox function" begin
        A2 = A .+ 0ε
        @test A2 ≈ A
        @test A ≈ A2
        @test (1.0 + 0ε) ≈ 1.0
        @test 1.0 ≈ (1.0 + 0ε)

        @test ~(M ≈ M .+ ε)
    end
end

println("DualMatrixTools tests finished!")
