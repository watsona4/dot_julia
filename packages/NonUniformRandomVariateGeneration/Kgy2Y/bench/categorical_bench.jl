using NonUniformRandomVariateGeneration
using Distributions
using BenchmarkTools
using Random
using StatsBase

function benchNative1(n::Int64, ps::Vector{Float64}, N::Int64)
  v::Vector{Int64} = Vector{Int64}(undef, n)
  for i in 1:N
    sampleCategoricalSorted!(v, ps)
  end
end

function benchNative2(n::Int64, ps::Vector{Float64}, N::Int64)
  v::Vector{Int64} = Vector{Int64}(undef, n)
  scratch1::Vector{Float64} = Vector{Float64}(undef, n)
  scratch2::Vector{Float64} = Vector{Float64}(undef, length(ps))
  for i in 1:N
    sampleCategoricalSorted!(v, ps, scratch1, scratch2)
  end
  return v
end

function benchDistributions(n::Int64, ps::Vector{Float64}, N::Int64)
  multinom = Distributions.Multinomial(n, ps)
  v::Vector{Int64} = Vector{Int64}(undef, n)
  a = Vector{Int64}(undef, length(ps))
  for i in 1:length(ps)
    a[i] = i
  end
  ws = StatsBase.weights(ps)
  for i in 1:N
    Distributions.sample!(a, ws, v)
  end
  return v
end

n = 10000
m = 1000
ps = exp.(randexp(m))
ps ./= sum(ps)
N = 1024

@btime benchNative1(n, ps, N)
@btime benchNative2(n, ps, N)
@btime benchDistributions(n, ps, N)
