using NonUniformRandomVariateGeneration
using Distributions
using BenchmarkTools

function benchNative(n::Int64, ps::Vector{Float64}, N::Int64)
  m::Vector{Int64} = zeros(Int64, length(ps))
  v::Vector{Int64} = Vector{Int64}(undef, length(ps))
  for i in 1:N
    sampleMultinomial!(n, ps, v)
    m .+= v
  end
  return m / N / n
end

function benchDistributions(n::Int64, ps::Vector{Float64}, N::Int64)
  multinom = Distributions.Multinomial(n, ps)
  m::Vector{Int64} = zeros(Int64, length(ps))
  v::Vector{Int64} = Vector{Int64}(undef, length(ps))
  for i in 1:N
    Distributions._rand!(multinom, v)
    m .+= v
  end
  return m / N / n
end

n = 100000
ps = [0.5; 0.1; 0.25; 0.15]

@btime benchNative(n, ps, 1024*1024*8)
@btime benchDistributions(n, ps, 1024*1024*8)
