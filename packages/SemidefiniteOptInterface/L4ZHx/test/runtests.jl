using SemidefiniteOptInterface
const SDOI = SemidefiniteOptInterface

using Compat
using Compat.Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

include("sdpa.jl")

const MOIU = MOI.Utilities
MOIU.@model(SDModelData,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan),
            (MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives,
             MOI.PositiveSemidefiniteConeTriangle),
            (),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction,),
            (MOI.VectorOfVariables,),
            ())

mock = SDOI.MockSDOptimizer{Float64}()
mock_optimizer = SDOI.SDOIOptimizer(mock, Float64)
@testset "supports_allocate_load" begin
    @test MOIU.supports_allocate_load(mock_optimizer, false)
    @test !MOIU.supports_allocate_load(mock_optimizer, true)
end
cached = MOIU.CachingOptimizer(SDModelData{Float64}(), mock_optimizer)
bridged = MOIB.full_bridge_optimizer(cached, Float64)
@testset "SolverName" begin
    @test MOI.get(mock,           MOI.SolverName()) == "MockSD"
    @test MOI.get(mock_optimizer, MOI.SolverName()) == "MockSD"
    @test MOI.get(cached,         MOI.SolverName()) == "MockSD"
    @test MOI.get(bridged,        MOI.SolverName()) == "MockSD"
end
config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Unit" begin
    include("unit.jl")
end
@testset "MOI Continuous Linear" begin
    include("contlinear.jl")
end
@testset "MOI Continuous Conic" begin
    include("contconic.jl")
end
