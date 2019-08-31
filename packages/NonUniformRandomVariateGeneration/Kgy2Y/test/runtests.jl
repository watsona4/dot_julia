using NonUniformRandomVariateGeneration
using Test

import Random.seed!

include("goodness_of_fit.jl")

@testset "Binomial tests" begin
  include("binomial_test.jl")
end

@testset "Multinomial tests" begin
  include("multinomial_test.jl")
end

@testset "Poisson tests" begin
  include("poisson_test.jl")
end

@testset "Gamma tests" begin
  include("gamma_test.jl")
end

@testset "Beta tests" begin
  include("beta_test.jl")
end

@testset "Uniform tests" begin
  include("uniform_test.jl")
end

@testset "Categorical tests" begin
  include("categorical_test.jl")
end
