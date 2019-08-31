## This is based on the definition of a Beta(α,β) random variable
@inline function sampleBeta(α::Float64, β::Float64,
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  X::Float64 = sampleGamma(α, rng)
  Y::Float64 = sampleGamma(β, rng)
  return X/(X+Y)
end
