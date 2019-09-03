## Makes the model associated with a particle filter using the "locally optimal
## proposal". Note that this is only optimal in the specific and limited sense
## that the weights are a function of xprev only, and hence the simulated value
## of x is not a source of variability.

mutable struct LGLOPParticle
  x::Float64
  xprev::Float64
  LGLOPParticle() = new()
end

function makeLGLOPModel(theta::LGTheta, ys::Vector{Float64})
  n::Int64 = length(ys)

  RC2v0::Float64 = theta.R + theta.C * theta.C * theta.v0
  v0RoverRC2v0::Float64 = theta.v0*theta.R/RC2v0
  sqrtv0RoverRC2v0::Float64 = sqrt(v0RoverRC2v0)

  mu1::Float64 = v0RoverRC2v0*(theta.x0/theta.v0 + theta.C*ys[1]/theta.R)
  tmp1::Float64 = theta.C * theta.x0 - ys[1]
  lG1::Float64 = -0.5 * log(2 * π * RC2v0) - tmp1 * 0.5/RC2v0 * tmp1

  RC2Q::Float64 = theta.R + theta.C * theta.C * theta.Q
  invRC2Qover2::Float64 = 0.5/RC2Q
  QRoverRC2Q::Float64 = theta.Q * theta.R / RC2Q
  sqrtQRoverRC2Q::Float64 = sqrt(QRoverRC2Q)

  invRover2::Float64 = 0.5/theta.R
  logncG::Float64 = -0.5 * log(2 * π * RC2Q)

  @inline function lG(p::Int64, particle::LGLOPParticle, ::Nothing)
    if p == 1
      return lG1
    else
      v::Float64 = theta.C * theta.A * particle.xprev - ys[p]
      return logncG - v * invRC2Qover2 * v
    end
  end
  @inline function M!(newParticle::LGLOPParticle, rng::RNG, p::Int64,
    particle::LGLOPParticle, ::Nothing)
    if p == 1
      newParticle.x = mu1 + sqrtv0RoverRC2v0*randn(rng)
    else
      mu::Float64 = QRoverRC2Q*(theta.A*particle.x/theta.Q + theta.C*ys[p]/theta.R)
      newParticle.x = mu + sqrtQRoverRC2Q*randn(rng)
      newParticle.xprev = particle.x
    end
  end
  model::SMCModel = SMCModel(M!, lG, n, LGLOPParticle, Nothing)
  return model
end
