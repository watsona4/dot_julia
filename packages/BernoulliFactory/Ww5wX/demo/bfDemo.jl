using BernoulliFactory
using Random
import Random.GLOBAL_RNG
import Statistics.mean

const p = 0.2
const fp() = rand() < p
vs = Vector{Bool}(undef, 100000)

f1 = _ -> BernoulliFactory.linear(fp, 2.0, 0.1)[1]
@time map!(f1, vs, vs)
2.0*p, mean(vs)

f2 = _ -> BernoulliFactory.inverse(fp, 0.1, 0.05)[1]
map!(f2, vs, vs)
0.1/p, mean(vs)

f3 = _ -> BernoulliFactory.power(fp, 0.8)[1]
map!(f3, vs, vs)
p^0.8, mean(vs)

f4 = _ -> BernoulliFactory.sqrt(fp)[1]
map!(f4, vs, vs)
sqrt(p), mean(vs)

f5 = _ -> BernoulliFactory.expMinus(fp, 3.0)[1]
map!(f5, vs, vs)
exp(-3.0*p), mean(vs)

f6 = _ -> BernoulliFactory.logistic(fp, 2.0)[1]
map!(f6, vs, vs)
2.0*p/(1+2.0*p), mean(vs)

const fp2() = rand() < 0.3
f7 = _ -> BernoulliFactory.twocoin(fp, fp2, 4.0, 3.0)[1]
map!(f7, vs, vs)
4.0*p/(4.0*p + 3.0*0.3), mean(vs)
