using OptimTestProblems
using OptimTestProblems.MultivariateProblems

import LinearAlgebra: norm

using Test

verbose = false

@testset "Bounded univariate problems" begin
    uvp = OptimTestProblems.UnivariateProblems.examples
    for (name, p) in uvp
        verbose && print_with_color(:green, "Problem: $name \n")
        for (miz, mia) in zip(p.minimizers, p.minima)
            @test p.f(miz) ≈ mia
        end
    end

end

@testset "Unconstrained multivariate problems" begin
    muvp = MultivariateProblems.UnconstrainedProblems.examples
    for (name, p) in muvp
        verbose && print_with_color(:green, "Problem: $name \n")
        soltest = !any(isnan, p.solutions)

        if startswith(name, "Penalty Function I")
            # The provided solutions are not exact
            tol = 1e-16
        else
            tol = 1e-32
        end

        f = objective(p)
        soltest && @test f(p.solutions) ≈ p.minimum

        gs = similar(p.initial_x)
        g! = gradient(p)
        g!(gs, p.solutions)
        soltest && @test norm(gs, Inf) < tol

        fg! = objective_gradient(p)
        fgs = similar(gs)
        g!(gs, p.initial_x)

        @test fg!(fgs, p.initial_x) ≈ f(p.initial_x)
        @test norm(fgs.-gs, Inf)  < eps(eltype(gs))
    end
end

@testset "Constrained multivariate problems" begin
    mcvp = MultivariateProblems.ConstrainedProblems.examples
    for (name, p) in mcvp
        verbose && print_with_color(:green, "Problem: $name \n")
        soltest = all(isfinite, p.solutions)

        f = objective(p)
        soltest && @test f(p.solutions) ≈ p.minimum

        if !isempty(p.constraintdata.lx)
            @test all(p.solutions .> p.constraintdata.lx)
        end
        if !isempty(p.constraintdata.ux)
            @test all(p.solutions .< p.constraintdata.ux)
        end

        lc = p.constraintdata.lc
        if !isempty(lc)
            c = fill(eltype(lc)(0.0), size(lc))
            p.constraintdata.c!(c, p.solutions)
            @test all(c .>= p.constraintdata.lc)
            @test all(c .<= p.constraintdata.uc)
        end

        # TODO: How do we test for optimality here?
        gs = similar(p.initial_x)
        g! = gradient(p)
        g!(gs, p.solutions)
        #soltest && @test norm(gs, Inf) < tol

        fg! = objective_gradient(p)
        fgs = similar(gs)
        g!(gs, p.initial_x)

        @test fg!(fgs, p.initial_x) ≈ f(p.initial_x)
        @test norm(fgs.-gs, Inf)  < eps(eltype(gs))
    end
end
