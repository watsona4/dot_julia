using SequentialMonteCarlo
using RNGPool
using SMCExamples.LinearGaussian: LGTheta, Float64Particle, kalmanlogZ,
  defaultLGModel, makeLGModel
import MonteCarloMarkovKernels: simulateChain!, makeAMKernel, kde, estimateBM
using StaticArrays
using StatsBase
using Plots
import Compat.Nothing
Plots.gr()
!isinteractive() && (ENV["GKSwstype"] = "100")

setRNGs(0)
lgModel, theta, ys, ko = defaultLGModel(100)

const truex0 = theta.x0
const truev0 = theta.v0
const trueC = theta.C

@inline function toLGTheta(v::SVector{3, Float64})
  return LGTheta(v[1], v[2], trueC, v[3], truex0, truev0)
end

t0 = SVector{3, Float64}(theta.A, theta.Q, theta.R)
const sigmaProp = SMatrix{3, 3, Float64}(Matrix{Float64}(I, 3, 3))

@inline function lglogprior(theta::LGTheta)
  if theta.A < 0 || theta.A > 10 return -Inf end
  if theta.Q < 0 || theta.Q > 10 return -Inf end
  if theta.R < 0 || theta.R > 10 return -Inf end
  return 0.0
end

function makelgsmcltd(ys::Vector{Float64}, N::Int64, nthreads::Int64)
  smcio = SMCIO{Float64Particle, Nothing}(N, length(ys), nthreads, false, 0.5)
  function ltd(in::SVector{3, Float64})
    theta::LGTheta = toLGTheta(in)
    lp::Float64 = lglogprior(theta)
    if lp == -Inf return -Inf end
    model::SMCModel = makeLGModel(theta, ys)
    smc!(model, smcio)
    return smcio.logZhats[length(ys)]
  end
end

function makelgkalmanltd(ys::Vector{Float64})
  function ltd(in::SVector{3, Float64})
    theta::LGTheta = toLGTheta(in)
    lp::Float64 = lglogprior(theta)
    if lp == -Inf return -Inf end
    return kalmanlogZ(theta, ys)
  end
end

logtargetSMC = makelgsmcltd(ys, 1024, Threads.nthreads())
logtargetKalman = makelgkalmanltd(ys)

PSMC = makeAMKernel(logtargetSMC, sigmaProp)
PKalman = makeAMKernel(logtargetKalman, sigmaProp)

srand(12345)
chainSMC = Vector{SVector{3, Float64}}(2^6)
simulateChain!(chainSMC, PSMC, t0)
chainSMC = Vector{SVector{3, Float64}}(2^15)
@time simulateChain!(chainSMC, PSMC, t0)
sar = PSMC(:acceptanceRate)

chainKalman = Vector{SVector{3, Float64}}(2^6)
simulateChain!(chainKalman, PKalman, t0)
chainKalman = Vector{SVector{3, Float64}}(2^20)
@time simulateChain!(chainKalman, PKalman, t0)
kar = PKalman(:acceptanceRate)

savefigures = false

vsKalman = Vector{Vector{Float64}}(3)
for i = 1:3
  vsKalman[i] = (x->x[i]).(chainKalman)
end
vsSMC = Vector{Vector{Float64}}(3)
for i = 1:3
  vsSMC[i] = (x->x[i]).(chainSMC)
end

plot(kde(vsSMC[1], sar))
plot!(kde(vsKalman[1], kar))
savefigures && savefig("pmmh_kde1.png")

plot(kde(vsSMC[2], sar))
plot!(kde(vsKalman[2], kar))
savefigures && savefig("pmmh_kde2.png")

plot(kde(vsSMC[3], sar))
plot!(kde(vsKalman[3], kar))
savefigures && savefig("pmmh_kde3.png")

contour(kde(vsSMC[1], vsSMC[2], sar))
contour!(kde(vsKalman[1], vsKalman[2], kar))
savefigures && savefig("pmmh_kde12.png")

contour(kde(vsSMC[1], vsSMC[3], sar))
contour!(kde(vsKalman[1], vsKalman[3], kar))
savefigures && savefig("pmmh_kde13.png")

contour(kde(vsSMC[2], vsSMC[3], sar))
contour!(kde(vsKalman[2], vsKalman[3], kar))
savefigures && savefig("pmmh_kde23.png")

plot(autocor(vsSMC[1]))
plot!(autocor(vsKalman[1]))
savefigures && savefig("pmmh_acf1.png")
plot(autocor(vsSMC[2]))
plot!(autocor(vsKalman[2]))
savefigures && savefig("pmmh_acf2.png")
plot(autocor(vsSMC[3]))
plot!(autocor(vsKalman[3]))
savefigures && savefig("pmmh_acf3.png")

estimateBM.(vsSMC)
estimateBM.(vsKalman)
