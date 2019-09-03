using SequentialMonteCarlo
using RNGPool
using SMCExamples.MVLinearGaussian
using StaticArrays

include("test.jl")

setRNGs(0)

model, theta, ys, ko = MVLinearGaussian.defaultMVLGModel(2, 10)
println(ko.logZhats)

## just run the algorithm a few times

testSMC(model, 1024*1024, 2, false)
testSMC(model, 1024*1024, 2, false, 0.5)
testSMCParallel(model, 1024*1024, 2, false)
testSMCParallel(model, 1024*1024, 2, false, 0.5)
