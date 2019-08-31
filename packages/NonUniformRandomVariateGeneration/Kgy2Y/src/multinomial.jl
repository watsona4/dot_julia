# sample a multinomial(n,p) r.v. using binomial r.v.s
@inline function sampleMultinomial!(n::Int64, p::Vector{Float64},
  result::Vector{Int64}, rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  nleft::Int64 = n
  tmp::Float64 = 0.0
  for i = 1:length(p)-1
    @inbounds result[i] = sampleBinomial(nleft, min(1.0, p[i] / (1.0 - tmp)), rng)
    @inbounds nleft -= result[i]
    @inbounds tmp += p[i]
  end
  @inbounds result[length(p)] = nleft;
  return
end

@inline function sampleMultinomial(n::Int64, p::Vector{Float64},
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  result::Vector{Int64} = Vector{Int64}(undef, length(p))
  sampleMultinomial!(n, p, result, rng)
  return result
end
