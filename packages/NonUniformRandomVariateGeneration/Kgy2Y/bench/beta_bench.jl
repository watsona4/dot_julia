using NonUniformRandomVariateGeneration
using Distributions
using BenchmarkTools

function benchNative(α::Float64, β::Float64, N::Int64)
  m::Float64 = 0.0
  for i in 1:N
    m += sampleBeta(α, β)
  end
  return m / N
end

function benchDistributions(α::Float64, β::Float64, N::Int64)
  beta = Distributions.Beta(α, β)
  m::Float64 = 0.0
  for i in 1:N
    m += rand(beta)
  end
  return m / N
end

@btime benchNative(1.5, 2.5, 1024*1024*8)
@btime benchDistributions(1.5, 2.5, 1024*1024*8)
