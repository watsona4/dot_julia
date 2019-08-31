using UnionFind

using Printf
using Test

@testset "Polymorphism" begin
    include("polymorphism.jl")
end

@testset "Table" begin
    include("table.jl")
end

@testset "Errors" begin
    include("errors.jl")
end

@testset "Benchmark" begin
    include("benchmark.jl")
end
