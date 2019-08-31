function testLogistic(p::Float64, C::Float64, m::Int64) where F<:Function
  testFunction(BernoulliFactory.logistic, m, C*p/(1.0+C*p), makef(p), C,
  GLOBAL_RNG)
end

Random.seed!(192837465)

testLogistic(0.4, 0.5, ntrials)
testLogistic(0.2, 1.0, ntrials)
testLogistic(0.1, 2.0, ntrials)
testLogistic(0.4, 2.0, ntrials)
testLogistic(0.4, 5.0, ntrials)
