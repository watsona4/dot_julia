using NonUniformRandomVariateGeneration
using Distributions
using BenchmarkTools

n = 100000
p = 0.25

function benchNative(n::Int64, p::Float64, N::Int64)
  m::Float64 = 0.0
  for i in 1:N
    m += sampleBinomial(n, p)
  end
  return m / N
end

function benchDistributions(n::Int64, p::Float64, N::Int64)
  binom = Distributions.Binomial(n, p)
  m::Float64 = 0.0
  for i in 1:N
    m += rand(binom)
  end
  return m / N
end

@btime benchNative(n, p, 1024*1024*8)
@btime benchDistributions(n, p, 1024*1024*8)
