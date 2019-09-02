## Define a particle consisting of all cluster variables for a Binomial mixture
## Assumes N is 25
mutable struct BinomCluster
  n::Int64                          # count of cluster members
  α::Array{Int64}     # count of occurrence of levels
  β::Array{Int64}           # The denominator in logprob calculation
  BinomCluster(dataFile::Matrix{Int64}) = new(0,
                                              ones(Int64, size(dataFile, 2)),
                                              ones(Int64, size(dataFile, 2)))
end

function calc_logprob(obs::Array{Int64}, cl::BinomCluster)
  out = 0.0
  for q in 1:length(obs)
    @inbounds out += - lgamma(obs[q] + 1) - lgamma(25 - obs[q] + 1) +
                    lgamma(cl.α[q] + obs[q]) + lgamma(25 - obs[q] + cl.β[q]) +
                    lgamma(cl.α[q] + cl.β[q]) -
                    lgamma(cl.α[q] + 25 + cl.β[q]) - lgamma(cl.α[q]) - lgamma(cl.β[q])
  end
  return out
end

function cluster_add!(cl::BinomCluster, obs::Array{Int64})
  @inbounds cl.n  += Int64(1)
  @inbounds cl.α  += obs
  @inbounds cl.β  += 25 .- obs
end
