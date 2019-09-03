using SequentialMonteCarlo
using RNGPool
import SMCExamples.LinearGaussian: defaultLGModel, makeLGLOPModel,
  makeLGAPFModel

setRNGs(0)

n = 1000
modelBootstrap, theta, ys, ko = defaultLGModel(n)

N = 1024*256
nt = Threads.nthreads()

println(ko.logZhats[n])

smcio = SMCIO{modelBootstrap.particle, modelBootstrap.pScratch}(N, n, nt, false, 2.0)
@time smc!(modelBootstrap, smcio)
@time smc!(modelBootstrap, smcio)
println([smcio.logZhats[n], N*smcio.Vhat1s[n]])

modelLOP = makeLGLOPModel(theta, ys)
smcio = SMCIO{modelLOP.particle, modelLOP.pScratch}(N, n, nt, false, 2.0)
@time smc!(modelLOP, smcio)
@time smc!(modelLOP, smcio)
println([smcio.logZhats[n], N*smcio.Vhat1s[n]])

modelAPF = makeLGAPFModel(theta, ys)
smcio = SMCIO{modelAPF.particle, modelAPF.pScratch}(N, n, nt, false, 2.0)
@time smc!(modelAPF, smcio)
@time smc!(modelAPF, smcio)
println([smcio.logZhats[n], N*smcio.Vhat1s[n]])
