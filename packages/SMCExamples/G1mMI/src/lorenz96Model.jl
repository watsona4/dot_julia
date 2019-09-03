## Creates a simple Euler--Maruyama discretization of a diffusion in which the
## drift coefficient corresponds to the Lorenz96 model and the diffusion
## coefficient is constant.

module Lorenz96

using SequentialMonteCarlo
using RNGPool
using StaticArrays
import SMCExamples.Particles.MVFloat64Particle
using Compat.Random
import Compat.undef

struct LorenzTheta
  σ::Float64
  F::Float64
  δ::Float64
  Δ::Float64
  steps::Int64
end

struct LorenzScratch{d}
  t1::MVector{d, Float64}
  t2::MVector{d, Float64}
end
LorenzScratch{d}() where d = LorenzScratch{d}(MVector{d, Float64}(undef),
  MVector{d, Float64}(undef))

@inline function lorenz(F::Float64, x::MVector{d, Float64},
  z::MVector{d, Float64}) where d
  @inbounds z[1] = (x[2] - x[d-1]) * x[d]
  @inbounds z[2] = (x[3] - x[d]) * x[1]
  for i = 3:d-1
    @inbounds z[i] = (x[i+1] - x[i-2]) * x[i-1]
  end
  @inbounds z[d] = (x[1] - x[d-2]) * x[d-1]
  z .+= F
end

function makeLorenzModel(theta::LorenzTheta,
  ys::Vector{SVector{d, Float64}}) where d
  n::Int64 = length(ys)
  σ::Float64 = theta.σ
  F::Float64 = theta.F
  invδ²over2 = 0.5 / (theta.δ * theta.δ)
  logncG = - 0.5 * d * log(2 * π * theta.δ * theta.δ)
  steps::Float64 = theta.steps
  Δ::Float64 = theta.Δ
  h::Float64 = Δ/steps
  sqrth::Float64 = sqrt(Δ/steps)

  @inline function lG(p::Int64, particle::MVFloat64Particle{d}, ::LorenzScratch{d})
    r::Float64 = 0.0
    for i = 1:d
      @inbounds v::Float64 = particle.x[i] - ys[p][i]
      r += logncG - v * invδ²over2 * v
    end
    return r
  end
  ## Euler--Maruyama
  @inline function M!(newParticle::MVFloat64Particle{d}, rng::RNG, p::Int64,
    particle::MVFloat64Particle{d}, scratch::LorenzScratch{d})
    if p == 1
      randn!(rng, newParticle.x)
      newParticle.x .*= σ
    else
      scratch.t1 .= particle.x
      for i = 1:steps
        lorenz(F, scratch.t1, scratch.t2)
        scratch.t2 .*= h
        randn!(rng, scratch.t1)
        scratch.t1 .*= σ * sqrth
        scratch.t1 .+= scratch.t2
      end
      newParticle.x .= scratch.t1
    end
  end
  return SMCModel(M!, lG, length(ys), MVFloat64Particle{d}, LorenzScratch{d})
end

function simulateLorenzModel(theta::LorenzTheta, d::Int64, n::Int64)
  model = makeLorenzModel(theta, Vector{SVector{d, Float64}}(undef, 0))
  ys = Vector{SVector{d, Float64}}(undef, n)
  xParticle = MVFloat64Particle{d}()
  xScratch = LorenzScratch{d}()
  rng = getRNG()
  for p in 1:n
    model.M!(xParticle, rng, p, xParticle, xScratch)
    ys[p] = xParticle.x + theta.δ * randn(rng, d)
  end
  return ys
end

function defaultLorenzModel(d::Int64, n::Int64)
  theta = LorenzTheta(0.5, 8.0, 0.7, 0.05, 20)
  ys = simulateLorenzModel(theta, d, n)
  model = makeLorenzModel(theta, ys)
  return model, theta, ys
end

end
