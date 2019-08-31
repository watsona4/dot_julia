using BernoulliFactory
using Random
import Random.GLOBAL_RNG
import Statistics: mean, var

μ() = rand()*3*π
m = 100000

vs = Vector{Float64}(undef, m)
flips = Vector{Int64}(undef, m)
calls = Vector{Int64}(undef, m)
for i in 1:m
  vs[i], flips[i], calls[i] = BernoulliFactory.signedEstimate(μ, sin, 1.0, 0.1, 1)
end
println("actual value = ", 2/(3*π))
println("estimated value = ", mean(vs))
println("variance of estimates = ", var(vs))
println("should be approx. standard normal: ", (mean(vs)-2/(3*π))/sqrt(var(vs)/m))
