# This file is part of Kpax3. License is MIT.

function logdPriorRow(p::Vector{Int},
                      ep::EwensPitmanPAUT)
  n = length(p)
  k = 0

  m = zeros(Int, n)

  for a in 1:n
    m[p[a]] += 1

    if m[p[a]] == 1
      k += 1
    end
  end

  logp = (k - 1) * log(ep.α) +
         SpecialFunctions.lgamma(ep.θ / ep.α + k) -
         SpecialFunctions.lgamma(ep.θ / ep.α + 1) +
         SpecialFunctions.lgamma(ep.θ + 1) -
         SpecialFunctions.lgamma(ep.θ + n) -
         k * SpecialFunctions.lgamma(1 - ep.α)

  for a in 1:n
    if m[a] > 0
      logp += SpecialFunctions.lgamma(m[a] - ep.α)
    end
  end

  logp
end

function logdPriorRow(n::Int,
                      k::Int,
                      m::Vector{Int},
                      ep::EwensPitmanPAUT)
  logp = (k - 1) * log(ep.α) +
         SpecialFunctions.lgamma(ep.θ / ep.α + k) -
         SpecialFunctions.lgamma(ep.θ / ep.α + 1) +
         SpecialFunctions.lgamma(ep.θ + 1) -
         SpecialFunctions.lgamma(ep.θ + n) -
         k * SpecialFunctions.lgamma(1 - ep.α)

  for a in 1:length(m)
    if m[a] > 0
      logp += SpecialFunctions.lgamma(m[a] - ep.α)
    end
  end

  logp
end

function logdPriorRow(p::Vector{Int},
                      ep::EwensPitmanPAZT)
  n = length(p)
  k = 0

  m = zeros(Int, n)

  for a in 1:n
    m[p[a]] += 1

    if m[p[a]] == 1
      k += 1
    end
  end

  logp = (k - 1) * log(ep.α) +
         SpecialFunctions.lgamma(k) -
         SpecialFunctions.lgamma(n) -
         k * SpecialFunctions.lgamma(1 - ep.α)

  for a in 1:n
    if m[a] > 0
      logp += SpecialFunctions.lgamma(m[a] - ep.α)
    end
  end

  logp
end

function logdPriorRow(n::Int,
                      k::Int,
                      m::Vector{Int},
                      ep::EwensPitmanPAZT)
  logp = (k - 1) * log(ep.α) +
         SpecialFunctions.lgamma(k) -
         SpecialFunctions.lgamma(n) -
         k * SpecialFunctions.lgamma(1 - ep.α)

  for a in 1:length(m)
    if m[a] > 0
      logp += SpecialFunctions.lgamma(m[a] - ep.α)
    end
  end

  logp
end

function logdPriorRow(p::Vector{Int},
                      ep::EwensPitmanZAPT)
  n = length(p)
  k = 0

  m = zeros(Int, n)

  for a in 1:n
    m[p[a]] += 1

    if m[p[a]] == 1
      k += 1
    end
  end

  logp = k * log(ep.θ) +
         SpecialFunctions.lgamma(ep.θ) -
         SpecialFunctions.lgamma(ep.θ + n)

  for a in 1:n
    if m[a] > 0
      logp += SpecialFunctions.lgamma(m[a])
    end
  end

  logp
end

function logdPriorRow(n::Int,
                      k::Int,
                      m::Vector{Int},
                      ep::EwensPitmanZAPT)
  logp = k * log(ep.θ) +
         SpecialFunctions.lgamma(ep.θ) -
         SpecialFunctions.lgamma(ep.θ + n)

  for a in 1:length(m)
    if m[a] > 0
      logp += SpecialFunctions.lgamma(m[a])
    end
  end

  logp
end

function logdPriorRow(p::Vector{Int},
                      ep::EwensPitmanNAPT)
  n = length(p)
  k = 0

  m = zeros(Int, n)

  for a in 1:n
    m[p[a]] += 1

    if m[p[a]] == 1
      k += 1
    end
  end

  log(prod((1:(k - 1)) .- ep.L) * ep.α^(k - 1) *
      exp(sum(SpecialFunctions.lgamma.(m[m .> 0] .- ep.α)) -
          k * SpecialFunctions.lgamma(1 - ep.α)) /
      prod((1:(n - 1)) .- ep.α * ep.L))
end

function logdPriorRow(n::Int,
                      k::Int,
                      m::Vector{Int},
                      ep::EwensPitmanNAPT)
  log(prod((1:(k - 1)) .- ep.L) * ep.α^(k - 1) *
      exp(sum(SpecialFunctions.lgamma.(m[m .> 0] .- ep.α)) -
          k * SpecialFunctions.lgamma(1 - ep.α)) /
      prod((1:(n - 1)) .- ep.α * ep.L))
end

"""
# Density of the Ewens-Pitman distribution

## Description

Probability of a partition according to the Ewens-Pitman distribution.

## Usage

dPriorRow(ep, p)
dPriorRow(ep, n, k, m)

## Arguments

* `ep` Object of (super)type EwensPitman
* `p` Vector of integers representing a partition
* `n` Set size (Integer)
* `k` Number of blocks (Integer)
* `m` Vector of integers representing block sizes

## Details

## Examples

"""
function dPriorRow(p::Vector{Int},
                   ep::EwensPitman)
  exp(logdPriorRow(p, ep))
end

function dPriorRow(n::Int,
                   k::Int,
                   m::Vector{Int},
                   ep::EwensPitman)
  exp(logdPriorRow(n, k, m, ep))
end
