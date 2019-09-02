## Define a particle consisting of all cluster variables for a Categorical mixture
mutable struct CategoricalCluster
  n::Float64                          # count of cluster members
  counts::Matrix{Int64}     # count of occurrence of levels
  nlevels::Array{Float64}           # The denominator in logprob calculation
  CategoricalCluster(dataFile::Matrix{Int64}) =
  new(0,
      zeros(Int64, maximum(dataFile), size(dataFile, 2)),
      # [0.5 * maximum(dataFile[:, d]) for d = 1:size(dataFile, 2)]
      0.5 * maximum(dataFile, dims = 1))
end


function calc_logprob(obs::Array{Int64}, cl::CategoricalCluster, featureFlag::Array)
  out = - sum(log.(cl.nlevels[featureFlag] .+ cl.n))
  @inbounds for q = 1:length(obs)
    if featureFlag[q]
      if cl.n == 0
        out += log(0.5)
      else
        out += log(0.5 + cl.counts[obs[q], q])
      end
    end
  end
  return out
end

function cluster_add!(cl::CategoricalCluster, obs::Array{Int64}, featureFlag::Array)
  @inbounds cl.n  += Int64(1)
  @simd for q = 1:length(obs)
    if featureFlag[q]
      @inbounds cl.counts[obs[q], q] += Int64(1)
    end
  end
  return
end

function calc_logmarginal(cl::CategoricalCluster)
  # This returns the log of the marginal likelihood of the cluster
  # Used for feature selection
  # β_0 = 0.5
  lm = zeros(Float64, length(cl.nlevels))
  for q in 1:length(cl.nlevels)
    lm[q] += lgamma(cl.nlevels[q] * 2) - lgamma.(cl.nlevels[q] * 2 .+ cl.n)
    for r in 1:Int64(2 * cl.nlevels[q])
      lm[q] += lgamma(cl.counts[r, q] + 0.5)

    end
  end
  return lm
end
using SpecialFunctions


"""
`coerce_categorical(data)`

Converts a matrix of categorical data into the format expected by particleMDI
## Input
- `data` an `n × d` matrix containing discrete values of which relatively few are unique.


## Output
- An `n × d` matrix where the discrete values are mapped to the range `1, 2, …, no. of unique values`. Ordering may not be preserved as ordering is irrelevant to this data type.
"""
function coerce_categorical(data)
  max_i = size(data, 1)
  max_j = size(data, 2)
  out = Matrix{Int64}(undef, max_i, max_j)
  for j in 1:max_j
    u = unique(data[:, j])
    for i in 1:max_i
      out[i, j] = Int64(findall(x -> x == data[i, j], u)[1])
    end
  end
  return out
end
