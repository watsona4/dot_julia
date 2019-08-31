using BernoulliFactory
using Random
import Random.GLOBAL_RNG
using Test

function makef(p::Float64, rng::RNG=GLOBAL_RNG) where RNG<:AbstractRNG
  @assert 0.0 <= p <= 1.0
  function f()
    return rand(rng) < p
  end
  return f
end

function testFunction(f::F1, m::Int64, v::Float64, fp::F2,
  args::Vararg{Any, N}) where {F1<:Function, F2<:Function, N}
  sumCoins::Int64 = 0
  for i in 1:m
    sumCoins += f(fp, args...)[1]
  end
  if v == 1.0 || v == 0.0
    @test sumCoins == m * v
  else
    @test abs((sumCoins/m - v))/sqrt(v*(1-v)/m) < 3
  end
end

ntrials = 100000

@testset "linear tests" begin
  @time include("linear_test.jl")
end

@testset "inverse tests" begin
  @time include("inverse_test.jl")
end

@testset "power tests" begin
  @time include("power_test.jl")
end

@testset "expminus tests" begin
  @time include("expminus_test.jl")
end

@testset "logistic tests" begin
  @time include("logistic_test.jl")
end

@testset "two coin tests" begin
  @time include("twocoin_test.jl")
end

@testset "signed estimate tests" begin
  @time include("signedEstimate_test.jl")
end
