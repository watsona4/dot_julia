using OptimBase
using Test
import Base.summary

struct FakeOptimizer <: Optimizer
end

@testset "summary" begin
    a_fake_optimizer = FakeOptimizer()
    @test_throws ErrorException summary(a_fake_optimizer)

    Base.summary(::FakeOptimizer) = "Fake Optimizer"
# add back when moving to v0.6
#    @test_nowarn summary(a_fake_optimizer)
end

@testset "optimization results" begin
    Base.summary(::FakeOptimizer) = "Fake Optimizer"
    uor = UnivariateOptimizationResults(FakeOptimizer(),
                                  0.1,
                                  0.2,
                                  0.3,
                                  0.0,
                                  10,
                                  false,
                                  true,
                                  0.1,
                                  0.2,
                                  OptimizationTrace{FakeOptimizer}(),
                                  32)
    @test OptimBase.summary(uor) == "Fake Optimizer"
    @test OptimBase.rel_tol(uor) == 0.1
    @test OptimBase.abs_tol(uor) == 0.2
    @test OptimBase.f_calls(uor) == 32
    #=
    type MultivariateOptimizationResults{O<:Optimizer,T,N,M} <: OptimizationResults
        method::O
        initial_x::Array{T,N}
        minimizer::Array{T,N}
        minimum::T
        iterations::Int
        iteration_converged::Bool
        x_converged::Bool
        x_tol::Float64
        x_residual::Float64
        f_converged::Bool
        f_tol::Float64
        f_residual::Float64
        g_converged::Bool
        g_tol::Float64
        g_residual::Float64
        f_increased::Bool
        trace::OptimizationTrace{M}
        f_calls::Int
        g_calls::Int
        h_calls::Int
    end
    =#
end
