import StatsFuns.chisqccdf

## generic goodness of fit testing

function discreteProbabilities(pmf::F, low::Int64,
  high::Int64) where F <: Function
  n::Int64 = high - low + 2
  probs::Vector{Float64} = Vector{Float64}(undef, n)
  for k in low:high
    probs[k-low+1] = pmf(k)
  end
  probs[n] = 1 - sum(probs[1:n-1])
  return probs
end

function continuousProbabilities(cdf::F, low::Float64, high::Float64,
  h::Float64) where F <: Function
  divisions::Vector{Float64} = Vector(low:h:high)
  n::Int64 = length(divisions)
  probs::Vector{Float64} = Vector{Float64}(undef, n)
  for i in 1:n-1
    probs[i] = cdf(divisions[i+1]) - cdf(divisions[i])
  end
  probs[n] = 1 - sum(probs[1:n-1])
  return probs
end

function testGOFMultinomial(probs::Vector{Float64}, counts::Vector{Int64})
  n::Int64 = sum(counts)
  es::Vector{Float64} = n .* probs
  if minimum(es) < 10.0
    println("warning: minimum expected value of ", minimum(es),
      " in bin ", indmin(es), " of ", n)
  end
  testStatistic::Float64 = sum((counts .- es).^2 ./ es)
  pValue::Float64 = chisqccdf(length(probs)-1, testStatistic)
  return pValue
end

function testGOFDiscrete(pmf::F1, sampler::F2, low::Int64, high::Int64,
  N::Int64) where {F1 <: Function, F2 <: Function}
  n = high - low + 2
  probs::Vector{Float64} = discreteProbabilities(pmf, low, high)
  counts::Vector{Int64} = Vector{Int64}(undef, n)
  fill!(counts, 0)
  for i in 1:N
    v::Int64 = sampler()
    if v < low || v > high
      counts[n] += 1
    else
      counts[v-low+1] += 1
    end
  end
  return testGOFMultinomial(probs, counts)
end

function testGOFContinuous(cdf::F1, sampler::F2, low::Float64, high::Float64,
  h::Float64, N::Int64) where {F1 <: Function, F2 <: Function}
  divisions::Vector{Float64} = Vector(low:h:high)
  n::Int64 = length(divisions)
  probs::Vector{Float64} = continuousProbabilities(cdf, low, high, h)
  counts::Vector{Int64} = Vector{Int64}(undef, n)
  fill!(counts, 0)
  for i in 1:N
    v::Float64 = sampler()
    if v < divisions[1] || v > divisions[n]
      counts[n] += 1
    else
      bin::Int64 = floor(Int64, (v - divisions[1])/h) + 1
      counts[bin] += 1
    end
  end
  return testGOFMultinomial(probs, counts)
end
