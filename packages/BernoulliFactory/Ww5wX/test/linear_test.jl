function testLinear(f::F, m::Int64, p::Float64, C::Float64) where F<:Function
  ϵ::Float64 = (1.0 - C*p)/2.0
  testFunction(f, m, C*p, makef(p), C, ϵ, GLOBAL_RNG)
end

Random.seed!(192837465)

testLinear(BernoulliFactory.linear, ntrials, 0.1, 2.0)
testLinear(BernoulliFactory.linear, ntrials, 0.4, 2.0)
testLinear(BernoulliFactory.linear, ntrials, 0.1, 3.0)
testLinear(BernoulliFactory.linear, ntrials, 0.6, 1.5)
testLinear(BernoulliFactory.linear, ntrials, 0.6, 0.4)

include("huber2017_test.jl")
