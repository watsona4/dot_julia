function testExpminus(p::Float64, λ::Float64, m::Int64)
  testFunction(BernoulliFactory.expMinus, m, exp(-λ*p), makef(p), λ, GLOBAL_RNG)
end

Random.seed!(192837465)

testExpminus(0.2, 1.0, ntrials)
testExpminus(0.8, 3.0, ntrials)
testExpminus(0.3, 0.5, ntrials)
