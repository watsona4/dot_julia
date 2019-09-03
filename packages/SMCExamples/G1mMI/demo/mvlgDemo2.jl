using SequentialMonteCarlo
using RNGPool
using SMCExamples.MVLinearGaussian
using StaticArrays

setRNGs(0)

model, theta, ys, ko = MVLinearGaussian.defaultMVLGModel(2, 100)

smcio = SMCIO{model.particle, model.pScratch}(2^15, model.maxn,
  Threads.nthreads(), true)
smc!(model, smcio)

predMeanSMC = SequentialMonteCarlo.eta(smcio, p -> p.x, false, smcio.n)
predVarSMC = SequentialMonteCarlo.eta(smcio,
  p -> (p.x - predMeanSMC) * (p.x - predMeanSMC)', false, smcio.n)
println("Predictive mean: $(ko.predictionMeans[smcio.n])")
println("Estimate: $predMeanSMC")
println("Predictive variance: $(ko.predictionVariances[smcio.n])")
println("Estimate: $predVarSMC")

filtMeanSMC = SequentialMonteCarlo.eta(smcio, p -> p.x, true, smcio.n)
filtVarSMC = SequentialMonteCarlo.eta(smcio,
  p -> (p.x - filtMeanSMC) * (p.x - filtMeanSMC)', true, smcio.n)
println("Filtering mean: $(ko.filteringMeans[smcio.n])")
println("Estimate: $filtMeanSMC")
println("Filtering variance: $(ko.filteringVariances[smcio.n])")
println("Estimate: $filtVarSMC")
