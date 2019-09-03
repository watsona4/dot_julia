## The standard univariate linear Gaussian state-space model example

module LinearGaussian

using SequentialMonteCarlo
using RNGPool
import SMCExamples.Particles.Float64Particle
import Compat: undef, Nothing

struct LGTheta
  A::Float64
  Q::Float64
  C::Float64
  R::Float64
  x0::Float64
  v0::Float64
end

function makeLGModel(theta::LGTheta, ys::Vector{Float64})
  n::Int64 = length(ys)
  sqrtQ::Float64 = sqrt(theta.Q)
  invRover2::Float64 = 0.5/theta.R
  sqrtv0::Float64 = sqrt(theta.v0)
  logncG::Float64 = -0.5 * log(2 * π * theta.R)
  @inline function lG(p::Int64, particle::Float64Particle, ::Nothing)
    @inbounds v::Float64 = theta.C*particle.x - ys[p]
    return logncG - v * invRover2 * v
  end
  @inline function M!(newParticle::Float64Particle, rng::RNG, p::Int64,
    particle::Float64Particle, ::Nothing)
    if p == 1
      newParticle.x = theta.x0 + sqrtv0*randn(rng)
    else
      newParticle.x = theta.A*particle.x + sqrtQ*randn(rng)
    end
  end
  return SMCModel(M!, lG, n, Float64Particle, Nothing)
end

function makelM(theta::LGTheta)
  tQ::Float64 = theta.Q
  negInvQover2::Float64 = -0.5/tQ
  tA::Float64 = theta.A
  @inline function lM(::Int64, particle::Float64Particle,
    newParticle::Float64Particle, ::Nothing)
    x::Float64 = particle.x
    y::Float64 = newParticle.x
    t::Float64 = tA*x - y
    return negInvQover2 * t * t
  end
  return lM
end

function simulateLGModel(theta::LGTheta, n::Int64)
  model = makeLGModel(theta, Vector{Float64}(undef, 0))
  ys = Vector{Float64}(undef, n)
  xParticle = Float64Particle()
  rng = getRNG()
  for p in 1:n
    model.M!(xParticle, rng, p, xParticle, nothing)
    ys[p] = theta.C*xParticle.x + sqrt(theta.R)*randn(rng)
  end
  return ys
end

function defaultLGModel(n::Int64)
  theta = LGTheta(0.9, 0.6, 1.2, 1.5, 1.0, 2.0)
  ys = simulateLGModel(theta, n)

  ko = kalman(theta, ys)

  lgModel = makeLGModel(theta, ys)

  return lgModel, theta, ys, ko
end

include("lgKalman.jl")
include("lgLOPModel.jl")
include("lgAPFModel.jl")

end
