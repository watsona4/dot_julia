## As defined in
## Mendo, L., 2016. An asymptotically optimal Bernoulli factory for certain
## functions that can be expressed as power series. arXiv:1612.08923
function _mendoPower(f::F, a::Float64, rng::RNG) where {F<:Function,
  RNG<:AbstractRNG}
  k::Int64 = 1
  X::Bool = false
  V::Bool = false
  flips::Int64 = 0
  while true
    X = f()
    flips += 1
    X && return true, flips
    V = rand(rng) < a/k
    V && return false, flips
    k += 1
  end
end
