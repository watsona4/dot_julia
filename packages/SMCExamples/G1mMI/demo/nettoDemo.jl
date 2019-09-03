using SequentialMonteCarlo
using RNGPool
import SMCExamples.Netto.defaultNettoModel

include("test.jl")

setRNGs(0)

model, theta, ys = defaultNettoModel(10)

numParticles = 1024*1024
numTrials = 2

## just run the algorithm a few times

testSMC(model, numParticles, numTrials, false)
testSMC(model, numParticles, numTrials, false, 0.5)

testSMCParallel(model, numParticles, numTrials, false)
testSMCParallel(model, numParticles, numTrials, false, 0.5)
