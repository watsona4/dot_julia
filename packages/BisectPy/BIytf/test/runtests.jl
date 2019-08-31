using BisectPy
using Test

@testset "BisectPy.jl" begin
    include("bisect_left.jl")
    include("bisect_right.jl")
end