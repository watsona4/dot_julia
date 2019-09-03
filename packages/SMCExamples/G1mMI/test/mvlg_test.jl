using SequentialMonteCarlo
using RNGPool
import SMCExamples.MVLinearGaussian.defaultMVLGModel
using Compat.Test

setRNGs(0)

N = 2^16
n = 10
nt = Threads.nthreads()
model, theta, ys, ko = defaultMVLGModel(2, n)

smcio = SMCIO{model.particle, model.pScratch}(N, n, nt, false)
smc!(model, smcio)
@test smcio.logZhats ≈ ko.logZhats atol=0.1
