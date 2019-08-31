## This is an implementation of
## Marsaglia, G. and Tsang, W.W., 2000. A simple method for generating gamma
## variables. ACM Transactions on Mathematical Software (TOMS), 26(3)
@inline function sampleGamma(α::Float64, rng::RNG) where RNG <: AbstractRNG
  @assert α > 0.0
  if α < 1.0
    return rand(rng)^(1/α)*sampleGamma(1.0+α, rng)
  end
  d::Float64 = α - 1/3
  c::Float64 = 1/sqrt(9*d)
  while true
    x::Float64 = randn(rng)
    v::Float64 = (1 + c*x)^3
    v < 0 && continue
    u::Float64 = rand(rng)
    x2::Float64 = x*x
    x4::Float64 = x2*x2
    if u < 1.0 - 0.0331*x4 return d*v end
    if log(u) < 0.5*x2 + d*(1-v+log(v))
      return d*v
    end
  end
end

@inline function sampleGamma(α::Float64, β::Float64,
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  return sampleGamma(α, rng) / β
end
