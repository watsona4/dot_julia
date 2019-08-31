function testTwocoin(p1::Float64, p2::Float64, C1::Float64, C2::Float64, m::Int64)
  f1::Function = makef(p1)
  f2::Function = makef(p2)
  v::Float64 = p1*C1/(p1*C1+p2*C2)
  testFunction(BernoulliFactory.twocoin, m, v, f1, f2, C1, C2, GLOBAL_RNG)
end

Random.seed!(192837465)

testTwocoin(0.1, 0.2, 5.0, 3.0, ntrials)
testTwocoin(0.4, 0.3, 2.0, 1.0, ntrials)
