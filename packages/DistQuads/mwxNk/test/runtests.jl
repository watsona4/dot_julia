using DistQuads, Distributions
using Test
import LinearAlgebra: norm

@testset "analytic vs quadrature" begin
    @testset "Beta" begin
        for a = 0.1:0.1:3.0, b = 0.1:0.1:3.0
            bd = Beta(a, b)
            dq = DistQuad(bd)
            # Test that mean function didn't accidentally regress
            @test mean(dq) == E(identity, dq)
            # Test nodes and weights against Distributions
            @test norm(mean(dq)-mean(bd), Inf) < 1e-8
            @test norm(var(dq)-var(bd), Inf) < 1e-8
            # Test nodes and weights against know mean (Distributions could in principle regress)
            @test norm(mean(dq)-a/(a+b), Inf) < 1e-8
            @test norm(var(dq)-a*b/((a+b+1)*(a+b)^2), Inf) < 1e-8
        end
    end
    @testset "Gamma" begin
        for a = 0.1:0.1:3.0, b = 0.1:0.1:3.0
            bd = Gamma(a, b)
            dq = DistQuad(bd)
            # Test that mean function didn't accidentally regress
            @test mean(dq) == E(identity, dq)
            # Test nodes and weights against Distributions
            @test norm(mean(dq)-mean(bd), Inf) < 1e-8
            @test norm(var(dq)-var(bd), Inf) < 1e-8
            # Test nodes and weights against know mean (Distributions could in principle regress)
            @test norm(mean(dq)-a*b, Inf) < 1e-8
            @test norm(var(dq)-a*b^2, Inf) < 1e-8
        end
    end
    @testset "Normal" begin
        for μ = 0.1:0.1:3.0, σ = 0.1:0.1:3.0
            bd = Normal(μ, σ)
            dq = DistQuad(bd)
            # Test that mean function didn't accidentally regress
            @test mean(dq) == E(identity, dq)
            # Test nodes and weights against Distributions
            @test norm(mean(dq)-mean(bd), Inf) < 1e-8
            @test norm(var(dq)-var(bd), Inf) < 1e-8
            # Test nodes and weights against know mean (Distributions could in principle regress)
            @test norm(mean(dq)-μ, Inf) < 1e-8
            @test norm(var(dq)-σ^2, Inf) < 1e-8
        end
    end
    @testset "LogNormal" begin
        for μ = 0.1:0.1:3.0, σ = 0.1:0.1:2.0
            bd = LogNormal(μ, σ)
            dq = DistQuad(bd)
            # Test that mean function didn't accidentally regress
            @test mean(dq) == E(identity, dq)
            # Test nodes and weights against Distributions
            @test norm(mean(dq)-mean(bd), Inf) < 1e-8
            @test norm(var(dq)-var(bd), Inf) < 1e-8 # not too precise!
            # Test nodes and weights against know mean (Distributions could in principle regress)
            @test norm(mean(dq)-exp(μ+σ^2/2), Inf) < 1e-8
            @test norm(var(dq)-(exp(σ^2)-1)*exp(2μ+σ^2), Inf) < 1e-8 # not too precise!
        end
    end
end
