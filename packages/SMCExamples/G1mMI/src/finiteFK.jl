## This model is primarily used for testing the SMC algorithm, since
## relevant quantities can be computed exactly

module FiniteFeynmanKac

using SequentialMonteCarlo
using RNGPool
using StaticArrays
import SMCExamples.Particles.Int64Particle
import Compat: undef, Nothing, findall

struct FiniteFK{d}
  mu::SVector{d, Float64}
  Ms::Vector{SMatrix{d, d, Float64}}
  Gs::Vector{SVector{d, Float64}}
end

let
  @inline function sample(probs::SVector{d, Float64}, u::Float64) where d
    i::Int64 = 1
    @inbounds while u > probs[i]
      @inbounds u -= probs[i]
      i += 1
    end
    return i
  end
  global function makeSMCModel(fk::FiniteFK{d}) where d
    n::Int64 = length(fk.Gs)
    mu::SVector{d, Float64} = fk.mu
    Ms = Matrix{SVector{d, Float64}}(undef, n-1, d)
    for p = 1:n-1
      for i = 1:d
        Ms[p,i] = fk.Ms[p][i, :]
      end
    end
    lGVectors::Vector{SVector{d, Float64}} =
      Vector{SVector{d, Float64}}(undef, n)
    for p = 1:n
      lGVectors[p] = log.(fk.Gs[p])
    end
    @inline function lG(p::Int64, particle::Int64Particle, ::Nothing)
      @inbounds return lGVectors[p][particle.x]
    end
    @inline function M!(newParticle::Int64Particle, rng::RNG, p::Int64,
      particle::Int64Particle, ::Nothing)
      if p == 1
        newParticle.x = sample(mu, rand(rng))
      else
        @inbounds probs::SVector{d, Float64} = Ms[p - 1, particle.x]
        @inbounds newParticle.x = sample(probs, rand(rng))
      end
    end
    return SMCModel(M!, lG, n, Int64Particle, Nothing)
  end
end

function makelM(ffk::FiniteFeynmanKac.FiniteFK{d}) where d
  n::Int64 = length(ffk.Gs)
  lMs::Matrix{SVector{d, Float64}} = Matrix{SVector{d, Float64}}(undef, n-1, d)
  for p in 1:n-1
    for i = 1:d
      lMs[p, i] = log.(ffk.Ms[p][i, :])
    end
  end
  @inline function lM(p::Int64, particle::Int64Particle, newParticle::Int64Particle,
    ::Nothing)
    x::Int64 = particle.x
    y::Int64 = newParticle.x
    @inbounds lMpx::SVector{d, Float64} = lMs[p-1, x]
    @inbounds v::Float64 = lMpx[y]
    return v
  end
  return lM
end

function randomFiniteFK(d::Int64, n::Int64)
  rng = getRNG()

  mu = rand(rng, d)
  mu ./= sum(mu)

  Ms = Vector{SMatrix{d, d, Float64}}(undef, n - 1)
  Gs = Vector{SVector{d, Float64}}(undef, n)
  for p = 1:n-1
    tmp = rand(rng, d, d)
    for i = 1:d
      tmp[i,:] ./= sum(tmp[i,:])
    end
    Ms[p] = SMatrix{d, d}(tmp)
  end
  for p = 1:n
    Gs[p] = SVector{d}(rand(rng, d))
  end
  return FiniteFK(SVector{d}(mu), Ms, Gs)
end

struct FiniteFKOut{d}
  etas::Vector{SVector{d, Float64}}
  etahats::Vector{SVector{d, Float64}}
  logZhats::Vector{Float64}
  etaGs::Vector{Float64}
  pis::Vector{SVector{d, Float64}}
  pihats::Vector{SVector{d, Float64}}
end

function calculateEtasZs(fk::FiniteFK{d}) where d
  n::Int64 = length(fk.Gs)
  etas = Vector{SVector{d, Float64}}(undef, n)
  etahats = Vector{SVector{d, Float64}}(undef, n)
  logZhats = Vector{Float64}(undef, n)
  etaGs = Vector{Float64}(undef, n)
  etas[1] = fk.mu
  tmp = MVector{d, Float64}(undef)
  tmp .= etas[1] .* fk.Gs[1]
  etaGs[1] = sum(tmp)
  logZhats[1] = log(etaGs[1])
  etahats[1] = tmp ./ etaGs[1]

  for p = 2:n
    etas[p] = etahats[p-1]' * fk.Ms[p-1]
    tmp .= etas[p] .* fk.Gs[p]
    etaGs[p] = sum(tmp)
    logZhats[p] = logZhats[p-1] + log(etaGs[p])
    etahats[p] = tmp ./ etaGs[p]
  end

  pis = Vector{SVector{d, Float64}}(undef, n)
  pihats = Vector{SVector{d, Float64}}(undef, n)
  pis[n] = etas[n]
  pihats[n] = etahats[n]
  Mbar = MMatrix{d, d, Float64}(undef)
  for p = n-1:-1:1
    for i = 1:d
      Mbar[i,:] = etahats[p] .* fk.Ms[p][:,i] ./ etas[p+1][i]
    end
    pis[p] = pis[p+1]' * Mbar
    pihats[p] = pihats[p+1]' * Mbar
  end

  return FiniteFKOut{d}(etas, etahats, logZhats, etaGs, pis, pihats)
end

function eta(ffkout::FiniteFKOut{d}, fv::SVector{d, Float64}, hat::Bool,
  p::Int64 = length(fk.Gs)) where d
  if hat
    return sum(ffkout.etahats[p] .* fv)
  else
    return sum(ffkout.etas[p] .* fv)
  end
end

function allEtas(ffkout::FiniteFKOut{d}, fv::SVector{d, Float64},
  hat::Bool) where d
  n::Int64 = length(ffkout.etas)
  result::Vector{Float64} = Vector{Float64}(undef, n)
  for p = 1:n
    @inbounds result[p] = eta(ffkout, fv, hat, p)
  end
  return result
end

function gamma(ffkout::FiniteFKOut{d}, fv::SVector{d, Float64}, hat::Bool,
  p::Int64 = length(fk.Gs)) where d
  idx::Int64 = p - 1 + hat
  logval = idx == 0 ? 0.0 : ffkout.logZhats[idx]
  v::Float64 = eta(ffkout, fv, hat, p)
  logval += log(abs(v))
  return (v >= 0, logval)
end

function allGammas(ffkout::FiniteFKOut{d}, fv::SVector{d, Float64},
  hat::Bool) where d
  n::Int64 = length(ffkout.etas)
  result::Vector{Tuple{Bool, Float64}} =
    Vector{Tuple{Bool, Float64}}(undef, n)
  for p = 1:n
    @inbounds result[p] = gamma(ffkout, fv, hat, p)
  end
  return result
end

function convertFunction(f::F, d::Int64) where F<:Function
  fv = MVector{d, Float64}(undef)
  v = Int64Particle()
  for i = 1:d
    v.x = i
    fv[i] = f(v)
  end
  return SVector{d, Float64}(fv)
end

# function eta(ffkout::FiniteFKOut{d}, f::F, hat::Bool,
#   p::Int64 = length(fk.Gs)) where {d, F<:Function}
#   return eta(ffkout, convertFunction(f, d), hat, p)
# end

function allEtas(ffkout::FiniteFKOut{d}, f::F, hat::Bool) where {d, F<:Function}
  return allEtas(ffkout, convertFunction(f, d), hat)
end

# function gamma(ffkout::FiniteFKOut{d}, f::F, hat::Bool,
#   p::Int64 = length(fk.Gs)) where {d, F<:Function}
#   return gamma(ffkout, convertFunction(f, d), hat, p)
# end

function allGammas(ffkout::FiniteFKOut{d}, f::F, hat::Bool) where {d,
  F<:Function}
  return allGammas(ffkout, convertFunction(f, d), hat)
end

function normalizeFiniteFK(fk::FiniteFK{d}, fkout::FiniteFKOut) where d
  n = length(fk.Gs)
  barGs = Vector{SVector{d, Float64}}(undef, n)
  for p = 1:n
    barGs[p] = fk.Gs[p] / fkout.etaGs[p]
  end
  return FiniteFK{d}(fk.mu,fk.Ms,barGs)
end

function _nuQpqf(fk::FiniteFK{d}, nu::SVector{d, Float64}, p::Int64, q::Int64,
  f::SVector{d, Float64}) where d
  if p == q
    return sum(nu .* f)
  end
  v = MVector{d,Float64}(nu)
  for i = p+1:q
    v .*= fk.Gs[i-1]
    v .= (v' * fk.Ms[i-1])'
  end
  return sum(v .* f)
end

function _Qpqf(fk::FiniteFK{d}, x::Int64, p::Int64, q::Int64,
  f::SVector{d, Float64}) where d
  v = zeros(MVector{d,Float64})
  v[x] = 1.0
  return _nuQpqf(fk, SVector{d, Float64}(v), p, q, f)
end

function _Qpqf(fk::FiniteFK{d}, p::Int64, q::Int64,
  f::SVector{d, Float64}) where d
  result = MVector{d, Float64}(undef)
  for x = 1:d
    result[x] = _Qpqf(fk, x, p, q, f)
  end
  return result
end

function _Qpnfs(fk::FiniteFK{d}, f::SVector{d, Float64}, n::Int64) where d
  result = Vector{MVector{d, Float64}}(undef, n)
  for p = 1:n
    result[p] = _Qpqf(fk, p, n, f)
  end
  return result
end

function _correctedeta(fk::FiniteFK{d}, nu::SVector{d, Float64}, p::Int64,
  n::Int64, resample::Vector{Bool}) where d
  if p == n || resample[p]
    return nu
  else
    q::Int64 = p
    v::MVector{d, Float64} = nu
    while !resample[q] && q < n
      v .*= (fk.Gs[q]).^2
      v = (v' * fk.Ms[q])'
      q += 1
    end
    return v
  end
end

function vpns(fk::FiniteFK{d}, fkout::FiniteFKOut, f::SVector{d, Float64},
  hat::Bool, centred::Bool, resample::Vector{Bool},
  n::Int64 = length(fk.Gs)) where d
  if centred
    return vpns(fk, fkout, f - eta(fkout, f, hat, n), hat, false, resample, n)
  end
  if hat
    return vpns(fk, fkout, f .* fk.Gs[n] / fkout.etaGs[n], false, false,
      resample, n)
  end
  ps::Vector{Int64} = [1 ; findall(resample[1:n-1]) .+ 1]

  nffk = normalizeFiniteFK(fk, fkout)
  Qpnfs_values = _Qpnfs(nffk, f, n)
  result = Vector{Float64}(undef, length(ps))
  etanfSq = eta(fkout, f, false, n)^2
  for i = 1:length(ps)
    p = ps[i]
    etap = fkout.etas[p]
    correctedetap = _correctedeta(nffk, etap, p, n, resample)
    if i == length(ps)
      q = n
    else
      q = ps[i+1]-1
    end
    result[i] = sum(correctedetap .* Qpnfs_values[q].^2) - etanfSq
  end
  return result
end

function vpns(fk::FiniteFK{d}, fkout::FiniteFKOut, f::F, hat::Bool,
  centred::Bool, resample::Vector{Bool},
  n::Int64 = length(fk.Gs)) where {d, F<:Function}
  return vpns(fk, fkout, convertFunction(f, d), hat, centred, resample, n)
end

function avar(fk::FiniteFK{d}, fkout::FiniteFKOut, f::SVector{d, Float64},
  hat::Bool, centred::Bool, resample::Vector{Bool},
  n::Int64 = length(fk.Gs)) where d
  return sum(vpns(fk, fkout, f, hat, centred, resample, n))
end

function avar(fk::FiniteFK{d}, fkout::FiniteFKOut, f::F, hat::Bool,
  centred::Bool, resample::Vector{Bool},
  n::Int64 = length(fk.Gs)) where {d, F<:Function}
  return sum(vpns(fk, fkout, convertFunction(f, d), hat, centred, resample, n))
end

function allavarhat1s(fk::FiniteFK{d}, fkout::FiniteFKOut,
  resample::Vector{Bool}) where d
  maxn = length(fk.Gs)
  result = Vector{Float64}(undef, maxn)
  f1 = ones(SVector{d, Float64})
  for n = 1:maxn
    result[n] = avar(fk, fkout, f1, true, false, resample, n)
  end
  return result
end

function Path2Int64(path::Vector{Int64Particle}, d::Int64)
  v::Int64 = 1
  for p = 1:length(path)
    v += d^(p-1)*(path[p].x-1)
  end
  return v
end

function Int642Path(v::Int64, d::Int64, n::Int64)
  path::Vector{Int64Particle} = Vector{Int64Particle}(undef, n)
  y = v - 1
  for p = 1:n
    path[p] = Int64Particle()
    path[p].x = 1 + mod(y, d)
    y = div(y, d)
  end
  return path
end

function fullDensity(ffk::FiniteFK, vec::Vector{Int64Particle})
  val::Float64 = ffk.mu[vec[1].x] * ffk.Gs[1][vec[1].x]
  for p = 2:length(vec)
    val *= ffk.Ms[p-1][vec[p-1].x,vec[p].x] * ffk.Gs[p][vec[p].x]
  end
  return val
end

end
