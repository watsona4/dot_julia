# This file is part of Kpax3. License is MIT.

abstract type PriorColPartition end

mutable struct AminoAcidPriorCol <: PriorColPartition
  logγ::Vector{Float64}
  logω::Vector{Vector{Float64}}

  A::Matrix{Float64}
  B::Matrix{Float64}
end

function AminoAcidPriorCol(data::Matrix{UInt8},
                           γ::Vector{Float64},
                           r::Float64)
  if length(γ) != 3
    throw(KInputError("Argument 'γ' does not have length 3."))
  elseif γ[1] < 0
    throw(KDomainError("Argument 'γ[1]' is negative."))
  elseif γ[2] < 0
    throw(KDomainError("Argument 'γ[2]' is negative."))
  elseif γ[3] < 0
    throw(KDomainError("Argument 'γ[3]' is negative."))
  end

  if r <= 0
    throw(KDomainError("Argument 'r' is negative."))
  end

  (m, n) = size(data)

  # probabilities must sum to one
  tot = γ[1] + γ[2] + γ[3]
  γ[1] /= tot
  γ[2] /= tot
  γ[3] /= tot

  # log(0) is -Inf
  # since we are going to multiply this matrix with a positive scalar (1 / k)
  # no NaN can be produced even if some γ[i] are zero
  # attributes 3 and 4 are both from property 3 -> use γ[3] twice
  logγ = [log(γ[1]); log(γ[2]); log(γ[3])]

  logω = Vector{Float64}[[log(k - 1) - log(k); -log(k)] for k in 1:n]

  n1s = zeros(Float64, m)
  for a in 1:n, b in 1:m
    n1s[b] += float(data[b, a])
  end

  A = zeros(Float64, 4, m)
  B = zeros(Float64, 4, m)

  if n > r
    for b in 1:m
      # uninformative attributes
      # If n > r, these two parameters sum to (r+1), i.e. the theoretical
      # sample size for the characteristic hyperparameters. This is done so
      # because we don't want them to be overwhelmed by the data.
      # The mean is the same to the one obtained with a Jeffreys prior
      A[1, b] = (r + 1) * (n1s[b] + 0.5) / (n + 1)
      B[1, b] = (r + 1) - A[1, b]

      # informative but not characteristic for any cluster
      A[2, b] = 1
      B[2, b] = 1

      # informative and characteristic... but for another cluster
      A[3, b] = 1
      B[3, b] = r

      # informative and characteristic for this cluster
      A[4, b] = r
      B[4, b] = 1
    end
  else
    for b in 1:m
      # uninformative attributes
      A[1, b] = n1s[b] + 0.5
      B[1, b] = n - n1s[b] + 0.5

      # informative but not characteristic for any cluster
      A[2, b] = 1
      B[2, b] = 1

      # informative and characteristic... but for another cluster
      A[3, b] = 1
      B[3, b] = r

      # informative and characteristic for this cluster
      A[4, b] = r
      B[4, b] = 1
    end
  end

  AminoAcidPriorCol(logγ, logω, A, B)
end
