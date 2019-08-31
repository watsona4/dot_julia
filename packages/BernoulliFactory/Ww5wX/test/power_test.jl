function testWastlundSqrt(p::Float64, m::Int64) where F<:Function
  testFunction(BernoulliFactory._wastlundSqrt, m, sqrt(p), makef(p), GLOBAL_RNG)
end

function testPower(p::Float64, a::Float64, m::Int64)
  testFunction(BernoulliFactory.power, m, p^a, makef(p), a, GLOBAL_RNG)
end

Random.seed!(192837465)

testWastlundSqrt(0.8, ntrials)
testWastlundSqrt(0.5, ntrials)
testWastlundSqrt(0.2, ntrials)
testWastlundSqrt(0.05, ntrials)

for p in [0.8;0.5;0.2;0.05]
  for a in [0.1;0.5;0.8;1.0;4.0]
    testPower(p, a, ntrials)
  end
end
