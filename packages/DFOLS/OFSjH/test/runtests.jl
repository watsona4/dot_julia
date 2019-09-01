using DFOLS
using Test, LinearAlgebra, Random

@testset "Vanilla Tests" begin
    # Rosenbrock
    rosenbrock = x -> [10. * (x[2]-x[1]^2), 1. - x[1]]
    initial_values = ([-1.2, 1.],
                      [-3.4, 5.6],
                      [20.0, 34.5],
                      [3.14159, π]
                    )
    for x0 in initial_values
        sol = solve(rosenbrock, [-1.2, 1.], user_params = Dict("init.random_initial_directions" => false))
        @test converged(sol) && flag(sol) == 0
        @test norm(residuals(sol)) < 1e-6
        @test abs(optimum(sol)) < 1e-10
        @test optimizer(sol)[1] ≈ 1.0
        @test optimizer(sol)[2] ≈ 1.0
    end
end

@testset "user_params Tests" begin
    rosenbrock = x -> [10. * (x[2]-x[1]^2), 1. - x[1]]
    x0 = [-1.2, 1.]
    # example with user_params dict
    @test converged(solve(rosenbrock, x0, user_params = Dict("init.random_initial_directions" => false,
                                            "model.abs_tol" => 1e-20,
                                            "noise.quit_on_noise_level" => false)))
    # empty dict literal
    @test converged(solve(rosenbrock, x0, user_params = Dict()))
end

@testset "Stochastic Objective Tests" begin
    Random.seed!(42)
    σ = 0.01
    μ = 1.
    rosenbrock = x -> [10. * (x[2]-x[1]^2), 1. - x[1]]
    rosenbrock_noisy = x -> rosenbrock(x) .* (μ .+ σ*randn(2))
    x0 = [-1.2, 1.0]
    soln = solve(rosenbrock_noisy, x0, objfun_has_noise=true)
    soln_nonoise = solve(rosenbrock_noisy, x0)
    @test converged(soln) # should see nf(soln) < nf(soln_nonoise)
    @test converged(soln_nonoise)
end

@testset "Boxed Optimization Tests" begin
    rosenbrock = x -> [10. * (x[2]-x[1]^2), 1. - x[1]]
    x0 = [-1.2, 1.0]
    bounds1 = ([-5., -5.], [5., 5,])
    bounds2 = ([-5., -5.], nothing)
    bounds3 = (nothing, [5., 5.])
    @test converged(solve(rosenbrock, x0, bounds = bounds1))
    @test converged(solve(rosenbrock, x0, bounds = bounds2))
    @test converged(solve(rosenbrock, x0, bounds = bounds3))
    @test converged(solve(rosenbrock, x0, bounds = nothing))
end

@testset "Julia Edge Cases" begin
    rosenbrock = x -> [10. * (x[2]-x[1]^2), 1. - x[1]]
    @test converged(solve(rosenbrock, [-1.2, 1.], bounds = ([-Inf, -Inf], nothing)))
    @test converged(solve(rosenbrock, [-1.2, 1.], bounds = ([-Inf, -Inf], [Inf, Inf])))
    f = x -> [0., 0.]
    sol = solve(f, [1., 100.])
    @test jacobian(sol) isa Nothing # Nothing part of the Union{Nothing, Matrix{TF}}
    @test converged(sol) && optimizer(sol) == [1., 100.] # general handling of the immediate resolution
end

@testset "Type Inference" begin
    rosenbrock = x -> [10. * (x[2]-x[1]^2), 1. - x[1]]
    @inferred solve(rosenbrock, [-1.2, 3.0], user_params = Dict("init.random_initial_directions" => false)); # will error if inference fails
    @test 1 == 1
end
