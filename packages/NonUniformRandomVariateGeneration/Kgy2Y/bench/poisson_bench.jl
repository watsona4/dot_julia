using NonUniformRandomVariateGeneration
using Distributions
using BenchmarkTools

function benchNative(μ::Float64, N::Int64)
  m::Float64 = 0.0
  for i in 1:N
    m += samplePoisson(μ)
  end
  return m / N
end

function benchDistributions(μ::Float64, N::Int64)
  pois = Distributions.Poisson(μ)
  m::Float64 = 0.0
  for i in 1:N
    m += rand(pois)
  end
  return m / N
end

@btime benchNative(5.0, 1024*1024*8)
@btime benchDistributions(5.0, 1024*1024*8)

@btime benchNative(10.0, 1024*1024*8)
@btime benchDistributions(10.0, 1024*1024*8)

@btime benchNative(20.0, 1024*1024*8)
@btime benchDistributions(20.0, 1024*1024*8)
