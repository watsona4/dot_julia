using SequentialMonteCarlo
using RNGPool
import SMCExamples.Lorenz96: defaultLorenzModel, LorenzTheta, makeLorenzModel
using Compat.Test

setRNGs(0)

N = 2^10
n = 10
nt = Threads.nthreads()
model, theta, ys = defaultLorenzModel(8, 100)

smcio = SMCIO{model.particle, model.pScratch}(N, n, nt, false)
smc!(model, smcio)
lzh1 = copy(smcio.logZhats)

theta2 = LorenzTheta(theta.σ, theta.F, theta.δ, theta.Δ, theta.steps*2)
model = makeLorenzModel(theta2, ys)
smc!(model, smcio)

@test smcio.logZhats ≈ lzh1 atol=1.0
