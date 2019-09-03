using SequentialMonteCarlo
using RNGPool
import SMCExamples.LinearGaussian: defaultLGModel, makeLGLOPModel,
  makeLGAPFModel, kalmanlogZ, makelM
using Compat.Test

setRNGs(0)

N = 32768
n = 10
nt = Threads.nthreads()
model, theta, ys, ko = defaultLGModel(n)

@test ko.logZhats[end] ≈ kalmanlogZ(theta, ys)

smcio = SMCIO{model.particle, model.pScratch}(N, n, nt, false)
smc!(model, smcio)
@test smcio.logZhats ≈ ko.logZhats atol=0.1

lM = makelM(theta)
p1 = smcio.internal.zetaAncs[1]
p2 = smcio.zetas[1]
lM(n, p1, p2, smcio.internal.particleScratch)

modelLOP = makeLGLOPModel(theta, ys)
smcio = SMCIO{modelLOP.particle, modelLOP.pScratch}(N, n, nt, false)
smc!(modelLOP, smcio)
@test smcio.logZhats ≈ ko.logZhats atol=0.1

modelAPF = makeLGAPFModel(theta, ys)
smcio = SMCIO{modelAPF.particle, modelAPF.pScratch}(N, n, nt, false, 2.0)
smc!(modelAPF, smcio)
@test smcio.logZhats[1:n-1] ≈ ko.logZhats[2:n] atol=0.1
