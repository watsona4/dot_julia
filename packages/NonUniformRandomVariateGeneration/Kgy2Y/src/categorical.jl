@inline function sampleCategoricalSorted!(vs::Vector{Int64}, p::Vector{Float64},
  unifs::Vector{Float64}, Fs::Vector{Float64},
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  sampleSortedUniforms!(unifs, rng)
  cumsum!(Fs, p)
  @inbounds maxFs = Fs[length(p)]
  j = 1
  for i = 1:length(vs)
    @inbounds while maxFs * unifs[i] > Fs[j]
      j += 1
    end
    @inbounds vs[i] = j
  end
end

@inline function sampleCategoricalSorted!(vs::Vector{Int64}, p::Vector{Float64},
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  unifs::Vector{Float64} = Vector{Float64}(undef, length(vs))
  Fs::Vector{Float64} = Vector{Float64}(undef, length(p))
  sampleCategoricalSorted!(vs, p, unifs, Fs, rng)
end

@inline function sampleCategoricalSorted(n::Int64, p::Vector{Float64},
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  vs::Vector{Int64} = Vector{Int64}(undef, n)
  sampleCategoricalSorted!(vs, p, rng)
  return vs
end

@inline function sampleCategorical(n::Int64, p::Vector{Float64},
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  vs::Vector{Int64} = sampleCategoricalSorted(n, p)
  shuffle!(rng, vs)
  return vs
end

@inline function sampleCategorical(ws::Vector{Float64}, sws::Float64,
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  u::Float64 = rand(rng) * sws
  i::Int64 = 1
  v::Float64 = ws[1]
  while u > v
    i += 1
    @inbounds v += ws[i]
  end
  return i
end

@inline function sampleCategorical(ws::Vector{Float64},
  rng::RNG = GLOBAL_RNG) where RNG <: AbstractRNG
  return sampleCategorical(ws, sum(ws), rng)
end
