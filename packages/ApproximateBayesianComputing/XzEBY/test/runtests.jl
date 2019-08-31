using ApproximateBayesianComputing
const ABC = ApproximateBayesianComputing
using Distributions

if VERSION >= v"0.7"
  using Random
  Random.seed!(1234)
  using Statistics
  using Distributed
  using Test
  #import Statistics: mean, median, maximum, minimum, quantile, std, var, cov, cor
else
  using Base.Test
  srand(1234)
end

include("test1.jl")

@time @test test1()


