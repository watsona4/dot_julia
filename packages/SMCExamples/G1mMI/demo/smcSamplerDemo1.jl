using SequentialMonteCarlo
using RNGPool
import SMCExamples.SMCSampler.defaultSMCSampler
using StaticArrays

include("test.jl")

setRNGs(0)

model, ltarget = defaultSMCSampler()

## just run the algorithm a few times

testSMC(model, 1024*1024, 2, false)
testSMC(model, 1024*1024, 2, false, 0.5)
testSMCParallel(model, 1024*1024, 2, false)
testSMCParallel(model, 1024*1024, 2, false, 0.5)
