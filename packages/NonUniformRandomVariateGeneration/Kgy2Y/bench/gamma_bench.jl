using NonUniformRandomVariateGeneration
using Distributions
using BenchmarkTools

function benchNative(α::Float64, β::Float64, N::Int64)
  m::Float64 = 0.0
  for i in 1:N
    m += sampleGamma(α, β)
  end
  return m / N
end

function benchDistributions(α::Float64, β::Float64, N::Int64)
  gam = Distributions.Gamma(α, 1/β)
  m::Float64 = 0.0
  for i in 1:N
    m += rand(gam)
  end
  return m / N
end

@btime benchNative(0.1, 1.0, 1024*1024*8)
@btime benchDistributions(0.1, 1.0, 1024*1024*8)

@btime benchNative(15.0, 1.0, 1024*1024*8)
@btime benchDistributions(15.0, 1.0, 1024*1024*8)
