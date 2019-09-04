using TakagiFactorization
using LinearAlgebra
using Test
using Random
using DoubleFloats

const N_RANDOM_TESTS=100

@testset "Takagi" begin
    @testset "Examples" begin
        A₁ = convert(Matrix{Complex{Float64}}, [1.0 2.0; 2.0 1.0])
        d₁, U₁ = takagi_factor(A₁)
        @test A₁ ≈ transpose(U₁) * d₁ * U₁ atol=2eps(Float64)*sum(abs.(A₁))
        @test d₁ ≈ Diagonal([3.0, 1.0]) atol=eps(Float64)*sum(d₁)
        @test U₁ ≈ [1 1; -1im 1im] / √2 atol=2eps(Float64)*sum(abs.(U₁))
        A₂ = convert(Matrix{Complex{Float64}}, [0.0 1.0; 1.0 0.0])
        d₂, U₂ = takagi_factor(A₂)
        @test A₂ ≈ transpose(U₂) * d₂ * U₂ atol=2eps(Float64)*sum(abs.(A₂))
        @test d₂ ≈ Diagonal([1.0, 1.0]) atol=eps(Float64)*sum(d₂)
        @test U₂ ≈ [1 1; -1im 1im] / √2 atol=2eps(Float64)*sum(abs.(U₂))
    end
    @testset "BigFloat" begin
        A₁ = convert(Matrix{Complex{BigFloat}}, [1.0 2.0; 2.0 1.0])
        d₁, U₁ = takagi_factor(A₁)
        @test A₁ ≈ transpose(U₁) * d₁ * U₁ atol=2eps(BigFloat)*sum(abs.(A₁))
        @test d₁ ≈ Diagonal([3.0, 1.0]) atol=eps(BigFloat)*sum(d₁)
        @test U₁ ≈ [1 1; -1im 1im] / √big(2) atol=2eps(BigFloat)*sum(abs.(U₁))
        A₂ = convert(Matrix{Complex{BigFloat}}, [0.0 1.0; 1.0 0.0])
        d₂, U₂ = takagi_factor(A₂)
        @test A₂ ≈ transpose(U₂) * d₂ * U₂ atol=2*eps(BigFloat)*sum(abs.(A₂))
        @test d₂ ≈ Diagonal([1.0, 1.0]) atol=eps(BigFloat)*sum(d₂)
        @test U₂ ≈ [1 1; -1im 1im] / √big(2) atol=2eps(BigFloat)*sum(abs.(U₂))
    end
    @testset "Sorting" begin
        @testset "Ascending" begin
            A₁ = convert(Matrix{Complex{Float64}}, [1.0 2.0; 2.0 1.0])
            d₁, U₁ = takagi_factor(A₁, sort=+1)
            @test A₁ ≈ transpose(U₁) * d₁ * U₁ atol=2eps(Float64)*sum(abs.(A₁))
            @test d₁ ≈ Diagonal([1.0, 3.0]) atol=eps(Float64)*sum(d₁)
            @test U₁ ≈ [-1im 1im; 1 1] / √2 atol=2eps(Float64)*sum(abs.(U₁))
            A₂ = convert(Matrix{Complex{Float64}}, [0.0 1.0; 1.0 0.0])
            d₂, U₂ = takagi_factor(A₂, sort=+1)
            @test A₂ ≈ transpose(U₂) * d₂ * U₂ atol=2eps(Float64)*sum(abs.(A₂))
            @test d₂ ≈ Diagonal([1.0, 1.0]) atol=eps(Float64)*sum(d₂)
            @test U₂ ≈ [1 1; -1im 1im] / √2 atol=2eps(Float64)*sum(abs.(U₂))
        end
        @testset "Descending" begin
            A₁ = convert(Matrix{Complex{Float64}}, [1.0 2.0; 2.0 1.0])
            d₁, U₁ = takagi_factor(A₁, sort=-1)
            @test A₁ ≈ transpose(U₁) * d₁ * U₁ atol=2eps(Float64)*sum(abs.(A₁))
            @test d₁ ≈ Diagonal([3.0, 1.0]) atol=eps(Float64)*sum(d₁)
            @test U₁ ≈ [1 1; -1im 1im] / √2 atol=2eps(Float64)*sum(abs.(U₁))
            A₂ = convert(Matrix{Complex{Float64}}, [0.0 1.0; 1.0 0.0])
            d₂, U₂ = takagi_factor(A₂, sort=-1)
            @test A₂ ≈ transpose(U₂) * d₂ * U₂ atol=2eps(Float64)*sum(abs.(A₂))
            @test d₂ ≈ Diagonal([1.0, 1.0]) atol=eps(Float64)*sum(d₂)
            @test U₂ ≈ [1 1; -1im 1im] / √2 atol=2eps(Float64)*sum(abs.(U₂))
        end
    end
    @testset "Exceptions" begin
        A₁ = convert(Matrix{Complex{Float64}}, [1 2; 3 4])
        @test_throws ArgumentError takagi_factor(A₁)
        A₂ = convert(Matrix{Complex{Float64}}, [1 2 3; 3 5 6])
        @test_throws ArgumentError takagi_factor(A₂)
        A₃ = convert(Matrix{Complex{Float64}}, [1 2; 2 1])
        U₃_good = zeros(Complex{Float64}, 2, 2)
        U₃_bad  = zeros(Complex{Float64}, 2, 3)
        d₃_good = zeros(Float64, 2)
        d₃_bad  = zeros(Float64, 3)
        @test_throws ArgumentError takagi_factor!(A₂, d₃_good, U₃_good)
        @test_throws ArgumentError takagi_factor!(A₃, d₃_good, U₃_bad )
        @test_throws ArgumentError takagi_factor!(A₃, d₃_bad , U₃_good)
        A₄ = fill(1.0+1.0im, 1, 1)
        @test_throws ArgumentError takagi_factor(A₄)
        A₅ = [1.0(i+j)+(i+j)^2*im for i in 1:3, j in 1:3]
        @test_throws ConvergenceError takagi_factor(A₅, maxsweeps=3)
    end
    @testset "3×3 matrix" begin
        A₃ = [1.0(i+j)+(i+j)^2*im for i in 1:3, j in 1:3]
        d₃, U₃ = takagi_factor(A₃)
        @test A₃ ≈ transpose(U₃) * d₃ * U₃
        @test d₃ ≈ Diagonal([
            4.4155861739535916e-2,
            3.0033913500521656,
            60.323939614868543
        ]) atol=eps(Float64)*sum(d₃)
        @test U₃ ≈ [
            +0.33545335144108862+0.40821295749675734im -0.47239985226318137-0.63226478108905759im +0.17953534721318656+0.25628093104221283im;
            +0.52042491538817959-0.58868255009056192im +0.21692804802171137-0.22840328588677278im -0.38789586814856813+0.36458431002027947im;
            +0.26495953910168601+0.18231959751983218im +0.41505791673853226+0.32493185886646364im +0.59888076930548662+0.50994513822719334im
        ] atol=3eps(Float64)*sum(abs.(U₃))
    end
    @testset "Random" begin
        symmetrize(A) = (A + transpose(A)) / 2
        Random.seed!(24363)
        for T in [Float32, Float64, BigFloat, Double32, Double64]
            for N = 2:16
                for k in 1:N_RANDOM_TESTS
                    for sort in -1:+1
                        A = symmetrize(rand(Complex{T}, N, N))
                        d, U = takagi_factor(A)
                        @test A ≈ transpose(U) * d * U atol=10*√(30*N^3)*eps(T)*sum(abs.(A)) # 10σ should be enough…
                    end
                end
            end
        end
    end
end
