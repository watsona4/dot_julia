function testInverse(p::Float64, C::Float64, m::Int64)
  ϵ::Float64 = (p - C)/2.0
  testFunction(BernoulliFactory.inverse, m, C/p, makef(p), C, ϵ, GLOBAL_RNG)
end

Random.seed!(192837465)

testInverse(0.8, 0.4, ntrials)
testInverse(0.5, 0.2, ntrials)
testInverse(0.9, 0.7, ntrials)
testInverse(0.15, 0.1, ntrials)
