using Distributions
using PointProcessInference


obs = rand(Exponential(2), 100)
res = PointProcessInference.inference(obs)

include(PointProcessInference.plotscript())
plotposterior(res)
