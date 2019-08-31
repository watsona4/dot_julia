import NonUniformRandomVariateGeneration.samplePoisson
import Random.GLOBAL_RNG

## linear is essentially an implementation of the Huber (2016) algorithm
"""
    linear(f::F, C::Float64, ϵ::Float64, rng::RNG=GLOBAL_RNG) where {F<:Function, RNG<:AbstractRNG}

Input:
  - ```f()``` simulates Bernoulli(p) random variates (of type Bool)
  - ```C >= 0```
  - ```ϵ ∈ (0,1)``` satisfying C*p < 1-⁠ϵ.
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```X, flips```
  - ```X``` is a Bernoulli(C*p) variate
  - ```flips``` is the number of calls of f()
"""
function linear(f::F, C::Float64, ϵ::Float64, rng::RNG=GLOBAL_RNG) where
  {F<:Function, RNG<:AbstractRNG}
  ϵ <= 0.0 || ϵ >= 1.0 && throw(DomainError(ϵ, "ϵ must be in (0,1)"))
  if C > 1.0
    return _huber2016(f, C, ϵ, rng)
  end
  if rand(rng) < C
    return f(), 1
  else
    return false, 0
  end
end

## inverse is an implementation of Algorithm 6 of
## Lee, A., Doucet, A. and Łatuszyński, K., 2014. Perfect simulation using
## atomic regeneration with application to Sequential Monte Carlo.
## arXiv:1407.5770
"""
    inverse(f::F, C::Float64, ϵ::Float64, rng::RNG=GLOBAL_RNG) where {F<:Function, RNG<:AbstractRNG}

Input:
  - ```f()``` simulates Bernoulli(p) random variates (of type Bool)
  - ```C ∈ [0,p)```
  - ```ϵ ∈ (0,1)``` satisfying p > C + ⁠ϵ.
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```X, flips```
  - ```X``` is a Bernoulli(C/p) variate
  - ```flips``` is the number of calls of f()
"""
function inverse(f::F, C::Float64, ϵ::Float64, rng::RNG=GLOBAL_RNG) where
  {F<:Function, RNG<:AbstractRNG}

  (C < 0.0 || C >= 1.0) && throw(DomainError(C, "C must be in [0,1)"))
  ϵ <= 0.0 && throw(DomainError(ϵ, "ϵ must be positive"))
  C+ϵ > 1.0 && throw(DomainError(C+ϵ, "C+ϵ cannot exceed 1.0"))

  fq = !f
  Cprime = 1.0/(1.0-C)
  ϵprime = ϵ/(1.0-C)
  flips::Int64 = 0
  k::Int64 = _sampleGeometric(C, rng)
  i::Int64 = 1
  while i < k
    X, newFlips = linear(fq, Cprime, ϵprime, rng)
    flips += newFlips
    if !X
      return false, flips
    end
    i += 1
  end
  return true, flips
end

## use Mendo's power algorithm
"""
    power(f::F, a::Float64, rng::RNG=GLOBAL_RNG) where {F<:Function, RNG<:AbstractRNG}

Input:
  - ```f()``` simulates Bernoulli(p) random variates (of type Bool)
  - ```a >= 0```
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```X, flips```
  - ```X``` is a Bernoulli(p^a) variate
  - ```flips``` is the number of calls of f()
"""
function power(f::F, a::Float64, rng::RNG=GLOBAL_RNG) where
  {F<:Function, RNG<:AbstractRNG}
  a < 0.0 && throw(DomainError(a, "a cannot be negative"))
  a == 0.0 && return true, 0
  a < 1.0 && return _mendoPower(f, a, rng)
  a == 1.0 && return f(), 1
  k = ceil(Int64, a)
  flips::Int64 = 0
  for i in 1:k
    X, newFlips = _mendoPower(f, a/k, rng)
    flips += newFlips
    !X && return false, flips
  end
  return true, flips
end

## use Mendo's power algorithm
"""
    sqrt(f::F, rng::RNG=GLOBAL_RNG) where {F<:Function, RNG<:AbstractRNG}

Input:
  - ```f()``` simulates Bernoulli(p) random variates (of type Bool)
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```X, flips```
  - ```X``` is a Bernoulli(sqrt(p)) variate
  - ```flips``` is the number of calls of f()
"""
function sqrt(f::F, rng::RNG=GLOBAL_RNG) where {F<:Function, RNG<:AbstractRNG}
  return _mendoPower(f, 0.5, rng)
end

## expMinus is based on series expansion of exp(-λp) = exp(λ(1-p))/exp(λ),
## which is a natural extension of Wastlund's observation for λ = 1
"""
    expMinus(f::F, λ::Float64, rng::RNG=GLOBAL_RNG) where {F<:Function, RNG<:AbstractRNG}

Input:
  - ```f()``` simulates Bernoulli(p) random variates (of type Bool)
  - ```λ >= 0```
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```X, flips```
  - ```X``` is a Bernoulli(exp(-λ*p)) variate
  - ```flips``` is the number of calls of f()
"""
function expMinus(f::F, λ::Float64, rng::RNG=GLOBAL_RNG) where
  {F<:Function, RNG<:AbstractRNG}
  λ < 0.0 && throw(DomainError(λ, "λ cannot be negative"))
  flips::Int64 = 0
  K::Int64 = samplePoisson(λ, rng)
  for i in 1:K
    if f()
      return false, flips + 1
    end
    flips += 1
  end
  return true, flips
end

## use the algorithm described in Huber (2017)
"""
    logistic(f::F, C::Float64, rng::RNG=GLOBAL_RNG) where {F<:Function, RNG<:AbstractRNG}

Input:
  - ```f()``` simulates Bernoulli(p) random variates (of type Bool)
  - ```C >= 0```
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```X, flips```
  - ```X``` is a Bernoulli(C*p/(1.0+C*p)) variate
  - ```flips``` is the number of calls of f()
"""
function logistic(f::F, C::Float64, rng::RNG=GLOBAL_RNG) where
  {F<:Function, RNG<:AbstractRNG}
  return _logistic(f, C, rng)
end

## described in
## Gonçalves, F.B., Łatuszyński, K.G. and Roberts, G.O., 2017. Exact Monte Carlo
## likelihood-based inference for jump-diffusion processes. arXiv:1707.00332
"""
    twocoin(f1::F1, f2::F2, C1::Float64, C2::Float64, rng::RNG=GLOBAL_RNG) where {F1<:Function, F2<:Function, RNG<:AbstractRNG}

Input:
  - ```f1()``` simulates Bernoulli(p1) random variates (of type Bool)
  - ```f2()``` simulates Bernoulli(p2) random variates (of type Bool)
  - ```C1, C2 >= 0```
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```X, flips```
  - ```X``` is a Bernoulli(C1*p1/(C1*p1+C2*p2)) variate
  - ```flips``` is the number of calls of f()
"""
function twocoin(f1::F1, f2::F2, C1::Float64, C2::Float64,
  rng::RNG=GLOBAL_RNG) where {F1<:Function, F2<:Function, RNG<:AbstractRNG}
  Cprob::Float64 = C1/(C1+C2)
  flips1::Int64 = 0
  flips2::Int64 = 0
  while true
    if rand(rng) < Cprob
      flips1 += 1
      if f1()
        return true, flips1, flips2
      end
    else
      flips2 += 1
      if f2()
        return false, flips1, flips2
      end
    end
  end
end

"""
signedEstimate(μ::F1, φ::F2, c::Float64, δ::Float64, n::Int64, rng::RNG=GLOBAL_RNG) where {F1<:Function, F2<:Function, RNG<:AbstractRNG} where {F1<:Function, F2<:Function, RNG<:AbstractRNG}

Input:
  - ```μ()``` simulates a random variate X
  - ```φ(X)``` is real-valued
  - ```c``` satisfies sup_x |φ(x)| <= c
  - ```δ > 0``` satisfies μ(φ) >= δ
  - ```n``` specifies a number of X variables to average
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```Y, flips, calls```
  - ```Y``` is almost surely valued in [0.0,c] with E[Y] = μ(φ)
  - ```flips``` is the number of coin tosses by the Bernoulli Factory algorithm
  - ```calls``` is the number of calls of μ() in total
"""
function signedEstimate(μ::F1, φ::F2, c::Float64, δ::Float64, n::Int64,
  rng::RNG=GLOBAL_RNG) where {F1<:Function, F2<:Function, RNG<:AbstractRNG}
  δ >= c && throw(DomainError("requires δ < c"))
  return _signedEstimate(μ, φ, c, δ, n, rng)
end

"""
signedEstimate(μ::F1, φ::F2, a::Float64, b::Float64, δ::Float64, c::Float64, n::Int64, rng::RNG=GLOBAL_RNG) where {F1<:Function, F2<:Function, RNG<:AbstractRNG}

Input:
  - ```μ()``` simulates a random variate X
  - ```φ(X)``` is real-valued
  - ```a,b,δ,c``` satisfy a <= inf_x φ(x) < b < δ <= μ(φ) < sup_x φ(x) <= c
  - ```n``` specifies a number of X variables to average
  - ```[rng]``` the RNG to used by the algorithm (does not affect f)
Output: ```Y, flips, calls```
  - ```Y``` is almost surely valued in [b, max{2b-a,c}] with E[Y] = μ(φ)
  - ```flips``` is the number of coin tosses by the Bernoulli Factory algorithm
  - ```calls``` is the number of calls of μ() in total
"""
function signedEstimate(μ::F1, φ::F2, a::Float64, b::Float64, δ::Float64,
  c::Float64, n::Int64, rng::RNG=GLOBAL_RNG) where {F1<:Function, F2<:Function,
  RNG<:AbstractRNG}
  !(a < b < δ < c) && throw(DomainError("requires a < b < δ < c"))
  return _signedEstimate(μ, φ, a, b, δ, c, n, rng)
end
