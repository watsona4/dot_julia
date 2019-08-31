## These methods are described in Appendix C of
## Lee, A., Doucet, A. and Łatuszyński, K., 2014. Perfect simulation using
## atomic regeneration with application to Sequential Monte Carlo. arXiv:1407.5770

function _signRejectionSample(μ::F1, φ::F2, c::Float64, rng::RNG) where
  {F1<:Function, F2<:Function, RNG<:AbstractRNG}
  while true
    v = φ(μ())
    if rand(rng) < abs(v)/c
      return sign(v) < 0
    end
  end
end

function _annotateμ(μ::F) where F<:Function
  calls = Ref(0)
  function ν()
    calls.x +=1
    return μ()
  end
  function νCalls()
    return calls.x
  end
  return ν, νCalls
end

function _signedEstimate(μ::F1, φ::F2, c::Float64, δ::Float64, n::Int64,
  rng::RNG) where {F1<:Function, F2<:Function, RNG<:AbstractRNG}
  ν, νCalls = _annotateμ(μ)
  q() = _signRejectionSample(ν, φ, c, rng)
  Y, flips = linear(q, 2.0, δ/c)
  if Y
    return 0.0, flips, νCalls()
  else
    v = 0.0
    for i in 1:n
      v += abs(φ(μ()))
    end
    return v/n, flips, νCalls()+n
  end
end

function _signedEstimate(μ::F1, φ::F2, a::Float64, b::Float64, δ::Float64,
  c::Float64, n::Int64, rng::RNG) where {F1<:Function, F2<:Function,
  RNG<:AbstractRNG}
  φnew(x) = φ(x) - b
  cnew = max(b-a, c-b)
  estimate, flips, calls = signedEstimate(μ, φnew, cnew, δ-b, n, rng)
  return estimate + b, flips, calls+n
end
