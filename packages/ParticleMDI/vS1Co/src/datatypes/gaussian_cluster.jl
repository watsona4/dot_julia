## Define a particle consisting of all cluster variables for a Gaussian mixture
## N is no. of potential clusters
## d is dimension of data
## n_obs is the number of observations
## n_levels is the number of levels, used in multinomial
## Priors:
# β_0 = 0.5
# α_0 = 1
# κ_0 = 0.001
# μ_0 = 0
mutable struct GaussianCluster
  n::Int64
  μ::Vector{Float64}   ## mean of observations in clusters
  Σ::Vector{Float64}   ## sum of observations in clusters
  λ::Vector{Float64}
  β::Vector{Float64}
  GaussianCluster(dataFile) =         new(0,
                                      Vector{Float64}(zeros(Float64, size(dataFile, 2))),
                                      Vector{Float64}(zeros(Float64, size(dataFile, 2))),
                                      Vector{Float64}(ones(Float64, size(dataFile, 2))),
                                      Vector{Float64}(ones(Float64, size(dataFile, 2))) .* 0.5)
end

function calc_logprob(obs::Array, cl::GaussianCluster, featureFlag::Array)
    out = sum(featureFlag) * (log(1 / sqrt(pi)) +
                          SpecialFunctions.lgamma(0.5 * cl.n + 1.0) -
                          SpecialFunctions.lgamma(0.5 * cl.n + 0.5))
    # Iterate over features
      @inbounds for q in 1:size(obs, 1)
        if featureFlag[q]
        out += 0.5 * (log(cl.λ[q]) - log(cl.n + 1.0)) -
                          (0.5 * cl.n + 1.0) *
                          log(1.0 + (1.0 / (cl.n + 1.0)) *
                          ((obs[q] - cl.μ[q]) ^ 2.0) * cl.λ[q])
        end
      end
      return out
  # """
end

function cluster_add!(cl::GaussianCluster, obs::Array, featureFlag::Array)
  cl.n     += 1
  @inbounds  for q = 1:length(obs)
    if featureFlag[q]
      cl.Σ[q]  += obs[q]
      cl.β[q] += (cl.n - 1 + 0.001) * (obs[q] - cl.μ[q]) ^ 2 / (2 * (cl.n + 0.001))
      cl.μ[q]  = cl.Σ[q] / (cl.n + 0.001)
      cl.λ[q]    = ((0.5 * cl.n + 0.5) * (cl.n + 0.001)) /
                      (cl.β[q] * (cl.n + 1.001))
    end
  end
  return
end

function calc_logmarginal(cl::GaussianCluster)
  # This returns the log of the marginal likelihood of the cluster
  # Used for feature selection
  α_n = (cl.n / 2 + 0.5)
  α_0 = 0.5
  β_n = cl.β
  β_0 = 0.5
  κ_0 = 0.001
  κ_n = cl.n + κ_0

  lm =  - α_n * log.(β_n) .+ ((α_0 * log(β_0)) .+
        lgamma(α_n) - lgamma(α_0) +
        0.5 * (log(κ_0) - log(κ_n)) -
        (cl.n * 0.5) * log(2 * π))
  return lm
end

function gaussian_normalise!(dataFile::Array)
  for d = 1:size(dataFile, 2)
    # μ = mean(dataFile[:, d])
    # σ = std(dataFile[:, d]) + eps(Float64)
    μ = median(dataFile[:, d])
    σ = 0.5 * μ - quantile(dataFile[:, d], 0.05) + eps(Float64)
    dataFile[:, d] = (dataFile[:, d] .- μ) ./ σ
  end
  return
end
