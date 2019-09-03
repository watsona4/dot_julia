## these are pre-defined particle types, only for convenience / as examples

module Particles

using StaticArrays
import Compat.undef

mutable struct Int64Particle
  x::Int64
  Int64Particle() = new()
end

@inline function Base.:(==)(x::Int64Particle, y::Int64Particle)
  return x.x == y.x
end

mutable struct Float64Particle
  x::Float64
  Float64Particle() = new()
end

@inline function Base.:(==)(x::Float64Particle, y::Float64Particle)
  return x.x == y.x
end

struct MVFloat64Particle{d}
  x::MVector{d, Float64}
  MVFloat64Particle{d}() where d = new(MVector{d, Float64}(undef))
end

@inline function Base.:(==)(x::MVFloat64Particle{d}, y::MVFloat64Particle{d}) where d
  return x.x == y.x
end

end
