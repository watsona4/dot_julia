using SequentialMonteCarlo
using RNGPool
import SMCExamples.SMCSampler.defaultSMCSampler
using StaticArrays
using Plots
Plots.gr()

setRNGs(0)

model, ltarget = defaultSMCSampler()

smcio = SMCIO{model.particle, model.pScratch}(1024*1024, model.maxn,
  Threads.nthreads(), false)
smc!(model, smcio)

xs = (p->p.x[1]).(smcio.zetas)
ys = (p->p.x[2]).(smcio.zetas)

## bimodal target needs a kde bandwidth adjustment since its variance is large
x, y, f = MonteCarloMarkovKernels.kde(xs, ys, 0.005)
contour(x, y, f)
contour!(x,y, (x,y) -> exp(ltarget((SVector{2,Float64}(x,y)))))
