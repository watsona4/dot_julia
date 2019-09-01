using Test
using ProjectiveVectors
using LinearAlgebra

function Base.isapprox(x::NTuple{N, <:Number}, y::NTuple{N, <:Number}; kwargs...) where {N}
    isapprox(collect(x), collect(y); kwargs...)
end

@testset "ProjectiveVectors" begin
    @testset "Constructor" begin
        x = PVector([1, 2, 3])
        @test x isa PVector{Int, 1}
        @test data(x) == [1, 2, 3]
        @test dims(x) == (2,)

        x = PVector([1, 2, 3, 4, 5, 6, 7, 8], (2, 2, 1))
        @test x isa PVector{Int, 3}
        @test dims(x) == (2, 2, 1)
        @test PVector([1, 2, 3], [4, 5, 6], [7, 8]) == x
    end

    @testset "embed" begin
        z = embed([2, 3])
        @test z isa PVector{Int, 1}
        @test data(z) == [2, 3, 1]

        z = embed([2, 3], [4, 5, 6])
        @test z isa PVector{Int, 2}
        @test data(z) == [2, 3, 1, 4, 5, 6, 1]
        @test dims(z) == (2, 3)

        z = embed([2, 3, 4, 5, 6, 7], (2, 3, 1))
        @test z isa PVector{Int, 3}
        @test dims(z) == (2, 3, 1)
        @test data(z) == [2, 3, 1, 4, 5, 6, 1, 7, 1]
    end

    @testset "Show" begin
        z = PVector([2, 3, 4, 5, 6, 7])
        @test sprint(show, z) == "PVector{Int64, 1}:\n [2, 3, 4, 5, 6, 7]"
        @test sprint(show, z, context=:compact => true) == "[2, 3, 4, 5, 6, 7]"

        z = embed([2, 3, 4, 5, 6, 7], (2, 3, 1))
        @test sprint(show, z) == "PVector{Int64, 3}:\n [2, 3, 1] × [4, 5, 6, 1] × [7, 1]"
        @test sprint(show, z, context=:compact => true) == "[2, 3, 1] × [4, 5, 6, 1] × [7, 1]"
    end

    @testset "Equality" begin
        # all same data layout but should be considered different
        z₁ = PVector([2, 3, 4, 5, 6, 7])
        z₂ = PVector([2, 3, 4, 5, 6, 7], (2, 2))
        z₃ = PVector([2, 3, 4, 5, 6, 7], (3, 1))

        @test z₁ ≠ z₂
        @test z₁ ≠ z₃
        @test z₂ ≠ z₃
        @test z₂ == z₂

        z₂_2 = PVector([2, 3, 4, 5.0, 6.0, 7.0], (2, 2))
        @test z₂ == z₂_2
    end

    @testset "Linear Algebra" begin
        z = embed([2.0, 3, 4, 5, 6, 7], (2, 3, 1))
        @test norm(z) ≈ (3.7416573867739413, 8.831760866327848, 7.0710678118654755)
        @test norm(normalize(z)) ≈ (1.0, 1.0, 1.0)
        @test norm(normalize(z, 2), 2) ≈ (1.0, 1.0, 1.0)
        @test norm(normalize(z, Inf), Inf) ≈ (1.0, 1.0, 1.0)

        z = embed([2.0, 3, 4, 5, 6, 7])
        @test norm(z) ≈ (11.832159566199232,)
        @test norm(normalize(z)) ≈ (1.0,)

        z = embed(rand(ComplexF64, 6), (2, 3, 1))
        @test norm(normalize(z)) ≈ (1.0, 1.0, 1.0)
        @test norm(normalize(z, 2), 2) ≈ (1.0, 1.0, 1.0)
        @test norm(normalize(z, Inf), Inf) ≈ (1.0, 1.0, 1.0)
    end

    @testset "affine_chart" begin
        w = [2.0, 3, 4, 5, 6, 7]
        z = embed(w, (2, 3, 1), normalize=true)
        @test affine_chart(z) ≈ w
        @test affine_chart!(zeros(6), z) ≈ w

        z = normalize(embed(w))
        @test affine_chart(z) ≈ w
        @test affine_chart!(zeros(6), z) ≈ w

        z = embed(w, normalize=true)
        @test affine_chart(z) ≈ w
        @test affine_chart!(zeros(6), z) ≈ w

        for T = [Float64, ComplexF64]
            w = rand(ComplexF64, 6)
            z = embed(w, (2, 3, 1), normalize=true)
            @test norm_affine_chart(z, 2) ≈ norm(w, 2)
            @test norm_affine_chart(z, Inf) ≈ norm(w, Inf)
        end
    end

    @testset "Dot, Fubini-Study" begin
        z = embed(rand(ComplexF64, 6), normalize=true)
        @test abs.(dot(z, z)) ≈ (1.0,)
        z = embed(rand(ComplexF64, 6), (2, 4), normalize=true)
        @test abs.(dot(z, z)) ≈ (1.0, 1.0)
        @test fubini_study(z, z) ≈ (0.0, 0.0)
    end
end
