using StochasticIntegrals
using Test

# Run tests

println("Test Stochastic Integral Generation")
@time @test include("new_tests.jl")
