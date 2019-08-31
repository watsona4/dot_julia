## generate a sorted array of uniform(0,1) r.v.s
## This is the uniform spacing method, Algorithm B on p. 214 of
## L. Devroye. Non-uniform random variate generation. 1986.

## this version only fills vec[start+1:start+n]
@inline function sampleSortedUniforms!(vec::Vector{Float64},
  start::Int64, n::Int64, rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  s::Float64 = 0.0
  for i = 1:n
    @inbounds vec[start + i] = randexp(rng)
    @inbounds s += vec[start + i]
  end
  G::Float64 = 1.0 / (s + randexp(rng))
  @inbounds vec[start + 1] *= G
  for i = 2:n
    @inbounds vec[start + i] *= G
    @inbounds vec[start + i] += vec[start + i - 1]
  end
end

## this version fills vec
@inline function sampleSortedUniforms!(vec::Vector{Float64},
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  sampleSortedUniforms!(vec, 0, length(vec), rng)
end

## this version creates a vector of length n and fills it
@inline function sampleSortedUniforms(n::Int64,
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  vec::Vector{Float64} = Vector{Float64}(undef, n)
  sampleSortedUniforms!(vec, rng)
  return vec
end
