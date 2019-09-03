using SequentialMonteCarlo
using RNGPool
import SMCExamples.SMCSampler: defaultSMCSampler, defaultSMCSampler1D
using Compat.Test

setRNGs(0)

model, ltarget = defaultSMCSampler()
n = model.maxn

smcio = SMCIO{model.particle, model.pScratch}(2^16, n, Threads.nthreads(),
  false)

smc!(model, smcio)

@test smcio.logZhats[n] ≈ 0.0 atol=0.1

model, ltarget = defaultSMCSampler1D()
n = model.maxn

smcio = SMCIO{model.particle, model.pScratch}(2^16, n, Threads.nthreads(),
  false)

smc!(model, smcio)

@test smcio.logZhats[n] ≈ 0.0 atol=0.1
