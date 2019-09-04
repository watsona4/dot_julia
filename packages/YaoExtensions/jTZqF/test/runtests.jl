using Test, Random, LinearAlgebra
using Yao
using YaoExtensions


@testset "QFT" begin
    include("QFT.jl")
end

@testset "CircuitBuild" begin
    include("CircuitBuild.jl")
end

@testset "RotBasis" begin
    include("RotBasis.jl")
end

@testset "Sequence" begin
    include("Sequence.jl")
end

@testset "Diff" begin
    include("Diff.jl")
end

@testset "timer" begin
    include("timer.jl")
end

@testset "Bag" begin
    include("Bag.jl")
end

@testset "ConditionBlock" begin
    include("ConditionBlock.jl")
end

@testset "hamiltonians" begin
    include("hamiltonians.jl")
end

@testset "Mod" begin
    include("Mod.jl")
end
