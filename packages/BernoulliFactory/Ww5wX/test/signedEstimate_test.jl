Random.seed!(192837465)
import Statistics.mean

function _getSignLinearValues(x0::Float64, n::Int64)
  μφ = 0.5-x0
  μg = x0^2-x0+0.5 # g = |φ|
  μgSq = x0^2-x0+1/3
  v = μφ/μg
  estimatorVariance = μg^2*v*(1-v)+v/n*(μgSq-μg^2)
  return μφ, μg, v, estimatorVariance
end

function _signLinearTest(x0::Float64, δ::Float64, c::Float64, n::Int64, m::Int64)
  μ() = rand()
  φ(x) = x-x0
  μφ, μg, v, estimatorVariance = _getSignLinearValues(x0, n)

  vs = Vector{Float64}(undef, m)
  flips = Vector{Int64}(undef, m)
  calls = Vector{Int64}(undef, m)
  for i in 1:m
    vs[i], flips[i], calls[i] = BernoulliFactory.signedEstimate(μ, φ, c, δ, n)
  end

  @test all(vs.>=0)
  @test all(vs.<=c)
  @test mean(vs.!= 0.0) ≈ v atol=0.01
  @test abs(mean(vs) - μφ)/sqrt(estimatorVariance/m) < 3

  for i in 1:m
    vs[i] > 0.0 && (calls[i] -= n)
  end
  @test mean(calls./flips) ≈ c/μg atol=0.1
end

function _signLinearTest(x0::Float64, a::Float64, b::Float64, δ::Float64,
  c::Float64, n::Int64, m::Int64)
  μ() = rand()
  φ(x) = x-x0
  _, μg, v, estimatorVariance = _getSignLinearValues(x0+b, n)
  μφ, _, _, _ = _getSignLinearValues(x0, n)

  vs = Vector{Float64}(undef, m)
  flips = Vector{Int64}(undef, m)
  calls = Vector{Int64}(undef, m)
  for i in 1:m
    vs[i], flips[i], calls[i] = BernoulliFactory.signedEstimate(μ, φ, a, b,
      δ, c, n)
  end

  @test all(vs.>=b)
  @test all(vs.<=max(2*b-a, c))
  @test mean(vs.!= b) ≈ v atol=0.01
  @test abs(mean(vs) - μφ)/sqrt(estimatorVariance/m) < 3

  for i in 1:m
    vs[i] > 0.0 && (calls[i] -= n)
  end
  @test mean(calls./flips) ≈ max(b-a,c-b)/μg atol=0.1
end

_signLinearTest(0.2, 0.1, 0.8, 3, ntrials)
_signLinearTest(0.4, 0.1, 1.0, 3, ntrials)
_signLinearTest(0.2, -0.2, 0.1, 0.2, 0.8, 5, ntrials)
