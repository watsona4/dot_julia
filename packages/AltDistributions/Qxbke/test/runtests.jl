using AltDistributions, Test, LinearAlgebra, Distributions, Random
using ForwardDiff: jacobian

Random.seed!(1)


# utilities

"Elements below the diagonal as a vector (by row)."
lower_to_vec(L) = vcat((L[i, 1:(i-1)] for i in 1:size(L, 1))...)

"Elements below and including the diagonal as a vector (by row)."
lowerdiag_to_vec(L) = vcat((L[i, 1:i] for i in 1:size(L, 1))...)

"""
Reconstruct lower triangular matrix (including diagonal) from a vector of
elemenst (by row).
"""
function vec_to_lowerdiag(l::AbstractVector{T}, n::Int) where T
    A = zeros(T, n, n)
    cumulative_index = 0
    for i in 1:n
        A[i, 1:i] .= l[cumulative_index .+ (1:i)]
        cumulative_index += i
    end
    LowerTriangular(A)
end

@testset "vec lower utilities" begin
    l = Float64.(1:6)
    L = vec_to_lowerdiag(l, 3)
    @test size(L) == (3, 3)
    @test eltype(L) == eltype(l)
    @test L == [1.0 0.0 0.0;
                2.0 3.0 0.0;
                4.0 5.0 6.0]
    @test lowerdiag_to_vec(L) == l
    @test lower_to_vec(L) == [2.0, 4.0, 5.0]
end

"Random covariance matrix."
randΣ(n) = (A = randn(n, n); A'*A)

"""
Random correlation matrix `Ω` and its Cholesky factor `F` such that `FF'=Ω`. The standard
deviations `σ` are returned as the 3rd value.
"""
function randΩFσ(n)
    Σ = randΣ(n)
    σ = .√diag(Σ)
    d = Diagonal(σ)
    Ω = Symmetric(d \ Σ / d)
    F = cholesky(Ω).L
    Ω, F, σ
end


# tests

@testset "LKJL" begin
    n = 7
    Ω, F, _ = randΩFσ(n)
    η = abs2(randn())
    J_full = jacobian(lowerdiag_to_vec(F)) do z
        F = vec_to_lowerdiag(z, n)
        lowerdiag_to_vec(F*F')
    end
    @test logdet(J_full) + logdet(Ω)*(η-1) ≈ logpdf(LKJL(η), F)
end

@testset "AltMvNormal" begin
    ns = 3:7

    @testset "plain vanilla covariance matrix" begin
        for _ in 1:1000
            n = rand(ns)
            μ = randn(n)
            Σ = randΣ(n)
            x = randn(n)
            @test logpdf(MvNormal(μ, Σ), x) ≈ logpdf(AltMvNormal(μ, Symmetric(Σ)), x)
        end
    end

    @testset "Σ = I" begin
        for _ in 1:1000
            n = rand(ns)
            μ = randn(n)
            x = randn(n)
            @test logpdf(MvNormal(μ, Diagonal(ones(n))), x) ≈ logpdf(AltMvNormal(μ, I), x)
        end
    end

    @testset "Cholesky factorization" begin
        for _ in 1:1000
            n = rand(ns)
            μ = randn(n)
            x = randn(n)
            Σ = randΣ(n)
            @test logpdf(MvNormal(μ, Σ), x) ≈ logpdf(AltMvNormal(μ, cholesky(Σ)), x)
        end
    end

    @testset "Diagonal Σ" begin
        for _ in 1:1000
            n = rand(ns)
            μ = randn(n)
            x = randn(n)
            d = abs2.(randn(n))
            Σ = Diagonal(d)
            @test logpdf(MvNormal(μ, Σ), x) ≈ logpdf(AltMvNormal(μ, Σ), x)
        end
    end

    @testset "plain vanilla covariance matrix" begin
        for _ in 1:1000
            n = rand(ns)
            μ = randn(n)
            Ω, F, σ = randΩFσ(n)
            L = Diagonal(σ)*F
            Σ = L*L'
            G = StdCorrFactor(σ, F)
            x = randn(n)
            @test logpdf(MvNormal(μ, Σ), x) ≈ logpdf(AltMvNormal(Val(:L), μ, G), x) rtol = 1e-6
        end
    end

    @testset "errors" begin
        @test_throws ArgumentError AltMvNormal(ones(3), Diagonal(ones(2)))
        @test_throws DimensionMismatch logpdf(AltMvNormal(ones(3), Diagonal(ones(3))), ones(2))
    end
end
