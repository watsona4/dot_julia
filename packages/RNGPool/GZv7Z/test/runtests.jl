using RNGPool
using Test

@testset "Parallel generation" begin
  @time include("test_pg.jl")
end

@testset "Small crush" begin
  @time include("smallCrush.jl")
end
