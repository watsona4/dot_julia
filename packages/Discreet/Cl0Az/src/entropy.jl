import StatsBase: entropy
entropy(probs::ProbabilityWeights) = -sum(x->(x * log(x)), probs[probs .> 0])


function entropy(counts::FrequencyWeights; method=:Naive)
    method == :Naive && return entropy_naive(counts)
    method == :Shrink && return entropy_shrinkage(counts)
    method == :CS && return entropy_cs(counts)
    throw(ArgumentError("Unknown method $method"))
end


entropy_naive(counts::FrequencyWeights) =
    entropy(ProbabilityWeights(counts / sum(counts)))


"Chao-Shen (2003) entropy estimator."
function entropy_cs(counts::FrequencyWeights)
  n = sum(counts)
  θ_ML = counts / n

  f1 = sum(counts .== 1)
  f1 = (f1 == n) ? n - 1 : f1 # avoid C=0

  # Estimate coverage
  C = (1 - f1 / n)
  p_a = C * θ_ML
  l_a = (1 .- (1 .- p_a) .^ n)

  return - sum(p_a .* log.(p_a) ./ l_a)
end


#=
From http://www.jmlr.org/papers/volume10/hausser09a/hausser09a.pdf
=#
"Shrinkage entropy estimator."
function entropy_shrinkage(counts::FrequencyWeights)
    n = sum(counts)
    θ_ML = counts / n

    # Uniform distribution
    t_k = 1 / length(θ_ML)

    den = (n - 1) * sum((θ_ML .- t_k) .^2)
    if den < 1e-10
      return entropy(ProbabilityWeights(θ_ML))
    else
      # Regularization parameter
      λ = (1 - sum(θ_ML .^ 2)) / den
      return entropy(ProbabilityWeights(λ * t_k .+ (1 - λ) * θ_ML))
    end
end


"""
Estimate the entropy of an array using a naive (frequencies-based),
Chao-Shen, or shrinkage estimator. Chao-Shen and shrinkage estimators reduce
the bias for small samples and a large number of classes.
"""
function estimate_entropy(data::AbstractVector; method::Symbol=:Naive)
  count_values = values(countmap(data))
  freqs = FrequencyWeights(collect(count_values))
  return entropy(freqs; method=method)
end


function estimate_joint_entropy(x::AbstractVector, y::AbstractVector; method::Symbol=:Naive)
  @assert length(x) == length(y) "Vectors must be the same length"

  count = countmap([hash(yᵢ, hash(xᵢ)) for (xᵢ, yᵢ) ∈ zip(x, y)])
  freqs = FrequencyWeights(collect(values(count)))
  entropy(freqs; method=method)
end
