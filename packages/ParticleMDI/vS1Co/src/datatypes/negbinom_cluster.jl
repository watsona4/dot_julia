## Define a particle consisting of all cluster variables for a Negative Binomial  mixture
## Priors:
# β_0 = 1
# α_0 = 1
# r = 1
mutable struct NegBinomCluster
  n::Int64
  Σ::Vector{Int64}   ## sum of observations in clusters
  NegBinomCluster(dataFile) =         new(0,
                                      Vector{Int64}(zeros(Int64, size(dataFile, 2))))
end

function calc_logprob(obs::Array, cl::NegBinomCluster, featureFlag::Array)

    # out = (lgamma(1 + cl.n + 1) - lgamma(1 + cl.n)) * sum(featureFlag)
    out = 0.0
    # Iterate over features
      @inbounds for q in 1:size(obs, 1)
        if featureFlag[q]
        # out += lgamma(1 + obs[q] + cl.Σ[q]) -
        #       lgamma(1 + cl.n + 1 + 1 + obs[q] + cl.Σ[q]) +
        #       lgamma(1 + cl.n + 1 + cl.Σ[q]) -
        #       lgamma(1 + cl.Σ[q])
       out += lgamma(1 + cl.n + 1) +
          lgamma(1 + obs[q] + cl.Σ[q]) +
          lgamma(1 + cl.n + 1 + cl.Σ[q]) -
          lgamma(1 + cl.n + 1 + 1 + obs[q] + cl.Σ[q]) -
          lgamma(1 + cl.n) - lgamma(1 + cl.Σ[q])
        end
      end
      return out
end

function cluster_add!(cl::NegBinomCluster, obs::Array, featureFlag::Array)
  cl.n     += 1
  @inbounds  for q = 1:length(obs)
    if featureFlag[q]
      cl.Σ[q]  += obs[q]
    end
  end
  return
end

function calc_logmarginal(cl::NegBinomCluster)
  # This returns the log of the marginal likelihood of the cluster
  # Used for feature selection
  lm = lgamma.(cl.Σ .+ 1) -
   lgamma.(cl.Σ .+ (cl.n + 1 + 1)) .+
   lgamma(1 + cl.n)
  return lm
end
