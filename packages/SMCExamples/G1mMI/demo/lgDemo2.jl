using SequentialMonteCarlo
using RNGPool
import SMCExamples.LinearGaussian.defaultLGModel
import SMCExamples.Particles.Float64Particle

setRNGs(0)

model, theta, ys, ko = defaultLGModel(100)

smcio = SMCIO{model.particle, model.pScratch}(1024*1024, model.maxn,
  Threads.nthreads(), false)
smc!(model, smcio)

predMeanSMC = SequentialMonteCarlo.eta(smcio, p -> p.x, false, smcio.n)
predVarSMC = SequentialMonteCarlo.eta(smcio, p -> p.x^2, false, smcio.n) -
  predMeanSMC^2
println("Predictive mean: $(ko.predictionMeans[smcio.n])")
println("Estimate: $predMeanSMC")
println("Predictive variance: $(ko.predictionVariances[smcio.n])")
println("Estimate: $predVarSMC")

filtMeanSMC = SequentialMonteCarlo.eta(smcio, p -> p.x, true, smcio.n)
filtVarSMC = SequentialMonteCarlo.eta(smcio, p -> p.x^2, true, smcio.n) -
  filtMeanSMC^2
println("Filtering mean: $(ko.filteringMeans[smcio.n])")
println("Estimate: $filtMeanSMC")
println("Filtering variance: $(ko.filteringVariances[smcio.n])")
println("Estimate: $filtVarSMC")

println("Running many particle filters with only 128 particles in parallel...")
m = 10000
lZs = Vector{Float64}(m)
Vs = Vector{Float64}(m)
lZhats = Vector{Float64}(m)
Vhats = Vector{Float64}(m)
f1(p::Float64Particle) = 1.0

nthreads = Threads.nthreads()
smcios = Vector{SMCIO}(nthreads)
Threads.@threads for i = 1:nthreads
  smcios[i] = SMCIO{model.particle, model.pScratch}(128, model.maxn, 1, true)
end
@time Threads.@threads for i = 1:m
  smcio = smcios[Threads.threadid()]
  smc!(model, smcio)
  lZs[i] = smcio.logZhats[smcio.n-1]
  Vs[i] = SequentialMonteCarlo.V(smcio, f1, false, false, smcio.n)
  lZhats[i] = smcio.logZhats[smcio.n]
  Vhats[i] = SequentialMonteCarlo.V(smcio, f1, true, false, smcio.n)
end

print("Empirical relative variance of Z_n^N: ")
println(var(exp.(lZs-ko.logZhats[smcio.n-1])))
print("Mean of unbiased estimator of relative variance of Z_n^N: ")
println(mean(Vs .* exp.(2*(lZs-ko.logZhats[smcio.n-1]))))
print("Estimated standard deviation of the value above: ")
println(sqrt(var(Vs .* exp.(2*(lZs-ko.logZhats[smcio.n-1])))/m))

print("Empirical relative variance of \hat{Z}_n^N: ")
println(var(exp.(lZhats-ko.logZhats[smcio.n])))
print("Mean of unbiased estimator of relative variance of \hat{Z}_n^N: ")
println(mean(Vhats .* exp.(2*(lZhats-ko.logZhats[smcio.n]))))
print("Estimated standard deviation of the value above: ")
println(sqrt(var(Vhats .* exp.(2*(lZhats-ko.logZhats[smcio.n])))/m))
