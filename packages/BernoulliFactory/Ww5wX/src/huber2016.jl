## Huber, M., 2016. Nearly optimal Bernoulli factories for linear functions.
## Combinatorics, Probability and Computing, 25(4), pp.577-591.
## input: f() returns a Bernoulli(p) variate, ϵ < 1-C*p
## output: a Bernoulli(C*p) variate, and the number of calls to f
function _huber2016(f::F, C::Float64, ϵ::Float64, rng::RNG) where
  {F<:Function, RNG<:AbstractRNG}
  γ::Float64 = 0.5
  k::Float64 = 2.3/(γ*ϵ)
  i::Int64 = 1
  ϵ = min(ϵ, 0.644)
  R::Bool = true
  flips::Int64 = 0
  while i != 0 && R
    α::Float64 = (C-1.0)/C
    while i != 0 && i < k
      B::Bool = f()
      flips += 1
      G::Int64 = _sampleGeometric(α, rng)
      i += (1-B)*G - 1
    end
    if i >= k
      R = rand(rng) < (1.0+γ*ϵ)^(-i)
      C *= 1.0+γ*ϵ
      ϵ *= (1.0-γ)
      k /= (1.0-γ)
    end
  end
  coin::Bool = i == 0
  return coin, flips
end
