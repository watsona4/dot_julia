using Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

import SeDuMi
const optimizer = SeDuMi.Optimizer()
MOI.set(optimizer, MOI.Silent(), true)

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "SeDuMi"
end

@testset "supports_allocate_load" begin
    @test MOIU.supports_allocate_load(optimizer, false)
    @test !MOIU.supports_allocate_load(optimizer, true)
end

# UniversalFallback is needed for starting values, even if they are ignored by SeDuMi
const cache = MOIU.UniversalFallback(MOIU.Model{Float64}())
const cached = MOIU.CachingOptimizer(cache, optimizer)

const bridged = MOIB.full_bridge_optimizer(cached, Float64)

config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Unit" begin
    MOIT.unittest(bridged, config, [
        # `TimeLimitSec` not supported.
        "time_limit_sec",
        # Error using pretransfo (line 149)
        # Size b mismatch
        "solve_unbounded_model",
        # Need https://github.com/JuliaOpt/MathOptInterface.jl/issues/529
        "solve_qp_edge_cases",
        # Integer and ZeroOne sets are not supported
        "solve_integer_edge_cases", "solve_objbound_edge_cases",
        "solve_zero_one_with_bounds_1",
        "solve_zero_one_with_bounds_2",
        "solve_zero_one_with_bounds_3"])
end

@testset "Continuous linear problems" begin
    MOIT.contlineartest(bridged, config, ["linear13"]) # See https://github.com/blegat/SeDuMi.jl/issues/7
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(bridged, config, ["pow", "rootdets", "exp", "logdet"])
end
