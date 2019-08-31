function testAlgorithmA(m::Int64, C::Float64, p::Float64, ntrials::Int64)
  r = C*p
  v = r*(1-r^(m-1))/(1-r^m)
  testFunction(BernoulliFactory._algorithmA, ntrials, v, makef(p), m, C,
    GLOBAL_RNG)
end

function testHighPowerLogistic(m::Int64, β::Float64, C::Float64, p::Float64,
  ntrials::Int64)
  r = C*p
  v = (β*r)^m./sum((β*r).^(0:m))
  testFunction(BernoulliFactory._highPowerLogistic, ntrials, v, makef(p), m, β, C,
    GLOBAL_RNG)
end

function testLinearSmall(f::F, m::Int64, p::Float64, C::Float64) where
  F<:Function
  ϵ = (1.0 - C*p)
  @assert ϵ > 0.5
  ϵ = (0.5 + ϵ)/2.0
  testFunction(f, m, C*p, makef(p), C, ϵ, GLOBAL_RNG)
end

Random.seed!(192837465)

testAlgorithmA(2, 2.0, 0.2, ntrials)
testAlgorithmA(3, 2.0, 0.2, ntrials)
testAlgorithmA(4, 2.0, 0.2, ntrials)

testHighPowerLogistic(2, 2.5, 2.0, 0.2, ntrials)
testHighPowerLogistic(3, 4.5, 3.0, 0.4, ntrials)

testLinear(BernoulliFactory._huber2017, ntrials, 0.1, 2.0)
testLinear(BernoulliFactory._huber2017, ntrials, 0.4, 2.0)
testLinear(BernoulliFactory._huber2017, ntrials, 0.1, 3.0)
testLinear(BernoulliFactory._huber2017, ntrials, 0.6, 1.5)

testLinearSmall(BernoulliFactory._huber2017Small, ntrials, 0.1, 2.0)
testLinearSmall(BernoulliFactory._huber2017Small, ntrials, 0.2, 2.0)
testLinearSmall(BernoulliFactory._huber2017Small, ntrials, 0.1, 4.0)
