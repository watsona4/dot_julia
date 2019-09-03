## Simple non-linear toy model proposed by:
## Netto, M., Gimeno, L. and Mendes, M., 1978. On the optimal and suboptimal
## nonlinear filtering problem for discrete-time systems. IEEE Transactions on
## Automatic Control, 23(6), pp.1062-1067.

module Netto

using SequentialMonteCarlo
using RNGPool
import SMCExamples.Particles.Float64Particle

import Compat: Nothing, undef

struct NettoTheta
  σ²::Float64
  δ²::Float64
end

function makeNettoModel(theta::NettoTheta, ys::Vector{Float64})
  n::Int64 = length(ys)
  σ::Float64 = sqrt(theta.σ²)
  invδ²over2::Float64 = 0.5 / theta.δ²
  logncG::Float64 = -0.5 * log(2 * π * theta.δ²)
  @inline function lG(p::Int64, particle::Float64Particle, ::Nothing)
    x::Float64 = particle.x
    tmp::Float64 = x*x/20.0
    v::Float64 = tmp - ys[p]
    return logncG - v * invδ²over2 * v
  end
  @inline function M!(newParticle::Float64Particle, rng::RNG, p::Int64,
    particle::Float64Particle, ::Nothing)
    if p == 1
      newParticle.x = σ*randn(rng)
    else
      x::Float64 = particle.x
      newParticle.x = x/2.0 + 25*x/(1.0+x*x) + 8*cos(1.2*p) + σ*randn(rng)
    end
  end
  model::SMCModel = SMCModel(M!, lG, n, Float64Particle, Nothing)
  return model
end

function simulateNettoModel(theta::NettoTheta, n::Int64)
  model = makeNettoModel(theta, Vector{Float64}(undef, 0))
  ys = Vector{Float64}(undef, n)
  xParticle = Float64Particle()
  rng = getRNG()
  for p in 1:n
    model.M!(xParticle, rng, p, xParticle, nothing)
    ys[p] = xParticle.x*xParticle.x/20.0 + sqrt(theta.σ²)*randn(rng)
  end
  return ys
end

function defaultNettoModel(n::Int64)
  theta = NettoTheta(0.9, 0.6)
  ys = simulateNettoModel(theta, n)

  model = makeNettoModel(theta, ys)

  return model, theta, ys
end

end
