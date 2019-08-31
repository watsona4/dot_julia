using Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

# Iterations:
# linear5 : > 1000, < 2000
# linear9 : > 3000, < 4000
# linear15: > 20000, Don't know if ever converges so we exclude it
import CDCS
optimizer = CDCS.Optimizer(maxIter=4000)
MOI.set(optimizer, MOI.Silent(), true)

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "CDCS"
end

@testset "supports_allocate_load" begin
    @test MOIU.supports_allocate_load(optimizer, false)
    @test !MOIU.supports_allocate_load(optimizer, true)
end

# UniversalFallback is needed for starting values, even if they are ignored by CDCS
const cache = MOIU.UniversalFallback(MOIU.Model{Float64}())
const cached = MOIU.CachingOptimizer(cache, optimizer)

const bridged = MOIB.full_bridge_optimizer(cached, Float64)

config = MOIT.TestConfig(atol=3e-2, rtol=3e-2)

@testset "Unit" begin
    MOIT.unittest(bridged, config, [
        # `TimeLimitSec` not supported.
        "time_limit_sec",
        # Need to investigate...
        "solve_with_lowerbound", "solve_affine_deletion_edge_cases", "solve_blank_obj",
        # Need https://github.com/JuliaOpt/MathOptInterface.jl/issues/529
        "solve_qp_edge_cases",
        # Error using cdcs_hsde.preprocess (line 14)
        # No variables in your problem?
        "solve_unbounded_model",
        # Integer and ZeroOne sets are not supported
        "solve_integer_edge_cases", "solve_objbound_edge_cases",
        "solve_zero_one_with_bounds_1",
        "solve_zero_one_with_bounds_2",
        "solve_zero_one_with_bounds_3"])
end

@testset "Continuous linear problems" begin
    MOIT.contlineartest(bridged, config, [
        # Need to investigate...
        "linear12", "linear15"])
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(bridged, config, [
        # rotatedsoc2: Returns Inf and -Inf instead of infeasibility certificate
        "rotatedsoc2",
        # Unsupported cones
        "pow", "rootdets", "exp", "logdet"])
end
