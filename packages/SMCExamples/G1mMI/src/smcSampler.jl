## Provides a very basic SMC sampler using random walk Metropolis proposals
## the first only allows one-dimensional states, the second allows any
## state of fixed-dimension

## This could clearly be improved to allow proposal covariance matrices to be
## supplied; currently only multipliers for an identity covariance are
## permitted. Perhaps more importantly, I would like to implement a
## mechanism for adaptively choosing the temperatures, e.g. by using the
## conditional ESS of:
## Zhou, Y., Johansen, A.M. and Aston, J.A., 2016. Toward Automatic Model
## Comparison: An Adaptive Sequential Monte Carlo Approach. Journal of
## Computational and Graphical Statistics, 25(3), pp. 701--726.
## A functional, generic SMC sampler could then be included in
## SequentialMonteCarlo.jl

module SMCSampler

using SequentialMonteCarlo
using RNGPool
using StaticArrays

import Compat: undef, Nothing
using Compat.LinearAlgebra
using Compat.Random

if VERSION >= v"0.7-"
  function mychol(A)
    return cholesky(A).L
  end
else
  function mychol(A)
    return chol(Symmetric(A))'
  end
end

## one-dimensional state
mutable struct SMCSP
  x::Float64
  lpibar0::Float64
  lpibar1::Float64
  SMCSP() = new()
end

## for one-dimensional states
function makeRWSMCSampler(mu, lpibar0, lpibar1, betas::Vector{Float64},
  taus::Vector{Float64}, iterations::Vector{Int64})
  n = length(betas)
  @assert n == length(taus) == length(iterations)

  @inline function lG(p::Int64, particle::SMCSP, ::Nothing)
    if p == n
      return 0.0
    end
    @inbounds return (betas[p + 1] - betas[p]) *
      (particle.lpibar1 - particle.lpibar0);
  end
  @inline function M!(newParticle::SMCSP, rng::RNG, p::Int64,
    particle::SMCSP, ::Nothing)
    if p == 1
      newParticle.x = mu(rng)
      newParticle.lpibar0 = lpibar0(newParticle.x)
      newParticle.lpibar1 = lpibar1(newParticle.x)
    else
      y::Float64 = particle.x
      lv0::Float64 = particle.lpibar0
      lv1::Float64 = particle.lpibar1
      for i = 1:iterations[p]
        @inbounds z::Float64 = y + taus[p] * randn(rng)
        z_lv0::Float64 = lpibar0(z)
        z_lv1::Float64 = lpibar1(z)
        @inbounds vy::Float64 = (1.0 - betas[p]) * lv0 + betas[p] * lv1
        @inbounds vz::Float64 = (1.0 - betas[p]) * z_lv0 + betas[p] * z_lv1
        lu::Float64 = -randexp(rng)
        if lu < vz - vy
          y = z
          lv0 = z_lv0
          lv1 = z_lv1
        end
      end
      newParticle.x = y
      newParticle.lpibar0 = lv0
      newParticle.lpibar1 = lv1
    end
  end
  return SMCModel(M!, lG, n, SMCSP, Nothing)
end

function defaultSMCSampler1D()
  function makenormlogpdf(mu::Float64, var::Float64)
    c1::Float64 = - 0.5 / var
    c2::Float64 = - 0.5 * log(2 * π * var)
    @inline function lpdf(x::Float64)
      v::Float64 = x - mu
      return c1*v*v + c2
    end
    return lpdf
  end

  betas::Vector{Float64} = [0, 0.0005, 0.001, 0.0025, 0.005, 0.01, 0.025, 0.05,
    0.1, 0.25, 0.5, 1]
  taus::Vector{Float64} = [0.0, 10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0,
    1.0, 1.0]
  iterations::Vector{Int64} = [0, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]

  x0::Float64 = 0.0
  v0::Float64 = 100.0
  sqrtv0::Float64 = sqrt(v0)

  lpibar0 = makenormlogpdf(x0, v0)
  @inline function mu(rng::RNG)
    return x0 + sqrtv0 * randn(rng)
  end

  lw1::Float64 = log(0.3)
  lw2::Float64 = log(0.7)
  lpdf1 = makenormlogpdf(-10.0, 0.01)
  lpdf2 = makenormlogpdf(10.0, 0.04)

  @inline function lpibar1(x::Float64)
    v1::Float64 = lw1 + lpdf1(x)
    v2::Float64 = lw2 + lpdf2(x)
    m::Float64 = max(v1, v2)
    return m + log(exp(v1 - m) + exp(v2 - m));
  end

  return makeRWSMCSampler(mu, lpibar0, lpibar1, betas, taus, iterations),
    lpibar1
end

## fixed-dimensional state
mutable struct SMCSamplerParticle{d}
  x::SVector{d, Float64}
  lpibar0::Float64
  lpibar1::Float64
  SMCSamplerParticle{d}() where d = new()
end

## scratch space for computations
struct SMCSScratch{d}
  tmp::MVector{d, Float64}
end
SMCSScratch{d}() where d = SMCSScratch{d}(MVector{d, Float64}(undef))

## for fixed-dimensional states
function makeRWSMCSampler(d::Int64, mu, lpibar0, lpibar1, betas::Vector{Float64},
  taus::Vector{Float64}, iterations::Vector{Int64})
  n = length(betas)
  @assert n == length(taus) == length(iterations)

  @inline function lG(p::Int64, particle::SMCSamplerParticle{d1},
    scratch::SMCSScratch{d1}) where d1
    if p == n
      return 0.0
    end
    return (betas[p + 1] - betas[p]) * (particle.lpibar1 - particle.lpibar0);
  end
  @inline function M!(newParticle::SMCSamplerParticle{d1}, rng::RNG, p::Int64,
    particle::SMCSamplerParticle{d1}, scratch::SMCSScratch{d1}) where d1
    if p == 1
      newParticle.x = mu(rng, scratch)
      newParticle.lpibar0 = lpibar0(newParticle.x)
      newParticle.lpibar1 = lpibar1(newParticle.x)
    else
      y::SVector{d1, Float64} = particle.x
      lv0::Float64 = particle.lpibar0
      lv1::Float64 = particle.lpibar1
      for i = 1:iterations[p]
        randn!(rng, scratch.tmp)
        z::SVector{d1, Float64} = y + taus[p] * scratch.tmp
        z_lv0::Float64 = lpibar0(z)
        z_lv1::Float64 = lpibar1(z)
        vy::Float64 = (1.0 - betas[p]) * lv0 + betas[p] * lv1
        vz::Float64 = (1.0 - betas[p]) * z_lv0 + betas[p] * z_lv1
        lu::Float64 = -randexp(rng)
        if lu < vz - vy
          y = z
          lv0 = z_lv0
          lv1 = z_lv1
        end
      end
      newParticle.x = y
      newParticle.lpibar0 = lv0
      newParticle.lpibar1 = lv1
    end
  end
  return SMCModel(M!, lG, n, SMCSamplerParticle{d}, SMCSScratch{d})
end

function defaultSMCSampler()
  function makelogMVN(μ::SVector{2, Float64}, Σ::SMatrix{2, 2, Float64})
    invΣ = inv(Σ)
    lognc = - 0.5 * 2 * log(2 * π) - 0.5 * logdet(Σ)
    function lpdf(x::SVector{d, Float64}) where d
      v = x - μ
      return lognc - 0.5*dot(v, invΣ * v)
    end
    return lpdf
  end

  betas = [0, 0.0005, 0.001, 0.0025, 0.005, 0.01, 0.025, 0.05,
    0.1, 0.25, 0.5, 1]
  taus = [0.0, 10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 1.0]
  iterations = [0, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]

  μ0 = SVector{2, Float64}(0.0, 0.0)
  Σ0 = SMatrix{2, 2, Float64}(100.0, 0.0, 0.0, 100.0)
  A0 = SMatrix{2, 2, Float64}(mychol(Σ0))

  lpibar0 = makelogMVN(μ0, Σ0)
  @inline function mu(rng::RNG, scratch::SMCSScratch{2})
    randn!(rng, scratch.tmp)
    return μ0 + A0 * scratch.tmp
  end

  lw1 = log(0.3)
  lw2 = log(0.7)
  μ11 = SVector{2, Float64}(-5.0, -5.0)
  Σ11 = SMatrix{2, 2, Float64}(0.01, 0.005, 0.005, 0.01)
  μ12 = SVector{2, Float64}(5.0, 5.0)
  Σ12 = SMatrix{2, 2, Float64}(0.04, -0.01, -0.01, 0.04)
  lpdf1 = makelogMVN(μ11, Σ11)
  lpdf2 = makelogMVN(μ12, Σ12)

  @inline function lpibar1(x::SVector{2, Float64})
    v1::Float64 = lw1 + lpdf1(x)
    v2::Float64 = lw2 + lpdf2(x)
    m::Float64 = max(v1, v2)
    return m + log(exp(v1 - m) + exp(v2 - m));
  end

  return makeRWSMCSampler(2, mu, lpibar0, lpibar1, betas, taus, iterations),
    lpibar1
end

end
