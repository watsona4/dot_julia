## Makes the model associated with a fully adapted auxiliary particle filter for
## a linear Gaussian state space model. This was introduced in:
## M. K. Pitt and N. Shephard. Filtering via simulation: Auxiliary particle
## filters. J. Amer. Statist. Assoc., 94(446):590--599, 1999.

function makeLGAPFModel(theta::LGTheta, ys::Vector{Float64})
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

  @inline function lG(p::Int64, particle::Float64Particle, ::Nothing)
    if p == n
      return p == 1 ? lG1 : 0.0
    end
    v::Float64 = theta.C * theta.A * particle.x - ys[p+1]
    v = logncG - v * invRC2Qover2 * v
    p == 1 && (v += lG1)
    return v
  end
  @inline function M!(newParticle::Float64Particle, rng::RNG, p::Int64,
    particle::Float64Particle, ::Nothing)
    if p == 1
      newParticle.x = mu1 + sqrtv0RoverRC2v0*randn(rng)
    else
      mu::Float64 = QRoverRC2Q*(theta.A*particle.x/theta.Q + theta.C*ys[p]/theta.R)
      newParticle.x = mu + sqrtQRoverRC2Q*randn(rng)
    end
  end
  return SMCModel(M!, lG, n, Float64Particle, Nothing)
end
