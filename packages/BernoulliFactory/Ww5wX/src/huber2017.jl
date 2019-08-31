## All of these methods are defined in
## Huber, M., 2017. Optimal linear Bernoulli factories for small mean problems.
## Methodology and Computing in Applied Probability, 19(2), pp.631-645.

function _logistic(f::F, C::Float64, rng::RNG) where {F<:Function,
  RNG<:AbstractRNG}
  A::Float64 = randexp(rng)
  T::Float64 = randexp(rng)/C
  flips::Int64 = 0
  while T < A
    B::Bool = f()
    flips += 1
    if B
      return true, flips
    else
      T += randexp(rng)/C
    end
  end
  return false, flips
end

function _algorithmA(f::F, m::Int64, C::Float64, rng::RNG) where {F<:Function,
  RNG<:AbstractRNG}
  s::Int64 = 1
  flips::Int64 = 0
  while 0 < s < m
    B, newFlips = _logistic(f, C, rng)
    flips += newFlips
    s += 1-2*B
  end
  return s == 0, flips
end

function _highPowerLogistic(f::F, m::Int64, β::Float64, C::Float64,
  rng::RNG) where {F<:Function, RNG<:AbstractRNG}
  s::Int64 = 1
  flips::Int64 = 0
  α::Float64 = β*C
  while 0 < s <= m
    B, newFlips = _logistic(f, α, rng)
    flips += newFlips
    s += 2*B-1
  end
  return s == m+1, flips
end

function _algorithmB(f::F, ϵ::Float64, m::Int64, β::Float64, C::Float64,
  rng::RNG) where {F<:Function, RNG<:AbstractRNG}

  γ::Float64 = 1.0-(1.0-ϵ)*β
  α::Float64 = β*C
  flips::Int64 = 0
  while true
    B1, newFlips = _huber2017(f, α, γ, rng)
    flips += newFlips
    if !B1
      return false, flips
    end
    B2, newFlips = _highPowerLogistic(f, m-2, β, C, rng)
    flips += newFlips
    if B2
      return true, flips
    end
    m -= 1
  end
end

function _huber2017(f::F, C::Float64, ϵ::Float64, rng::RNG) where {F<:Function,
  RNG<:AbstractRNG}
  m::Int64 = ceil(Int64, 4.5/ϵ) + 1
  β::Float64 = 1.0 + 1.0/(m-1.0)
  flips::Int64 = 0
  B1, newFlips = _algorithmA(f, m, β*C, rng)
  flips += newFlips
  if !B1 return false, flips end
  if rand(rng) < 1.0/β
    return true, flips
  else
    B, newFlips = _algorithmB(f, ϵ, m, β, C, rng)
    flips += newFlips
    return B, flips
  end
end

function _huber2017Small(f::F, C::Float64, ϵ::Float64, rng::RNG) where {F<:Function,
  RNG<:AbstractRNG}
  @assert ϵ > 0.5
  M::Float64 = 1.0 - ϵ
  β::Float64 = 1.0/(1.0-2*M)
  Y, flips = _logistic(f, β*C, rng)
  if !Y return false, flips end
  B::Bool = rand(rng) < 1/β
  if B return true, flips end
  ϵ = 1.0 - β/(β-1.0)*M
  X, newFlips = _huber2017(f, C*β/(β-1.0), ϵ, rng)
  return X, flips + newFlips
end
