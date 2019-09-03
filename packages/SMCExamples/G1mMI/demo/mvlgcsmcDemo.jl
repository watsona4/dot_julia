using SequentialMonteCarlo
using RNGPool
using SMCExamples.MVLinearGaussian
import SMCExamples.Particles.MVFloat64Particle
using StaticArrays
using Plots
Plots.gr()

setRNGs(0)

model, theta, ys, ko = MVLinearGaussian.defaultMVLGModel(2, 10)

nsamples = 2^14

smcio = SMCIO{model.particle, model.pScratch}(16, model.maxn, 1, true, 2.0)

v = Vector{MVFloat64Particle{2}}(10)
for p = 1:10
  v[p] = MVFloat64Particle{2}()
  v[p].x .= zeros(MVector{2, Float64})
end

function smoothingMeans(model, smcio, m, v)
  tmp = Vector{MVector{2,Float64}}(10)
  for p = 1:10
    tmp[p] = zeros(MVector{2, Float64})
  end
  for i = 1:m
    csmc!(model, smcio, v, v)
    for p = 1:10
      tmp[p] .+= v[p].x
    end
  end
  return tmp ./ m
end

@time out = smoothingMeans(model, smcio, nsamples, v)
plot((x -> x[1]).(out))
plot!((x -> x[1]).(ko.smoothingMeans), color=:red)

plot((x -> x[2]).(out))
plot!((x -> x[2]).(ko.smoothingMeans), color=:red)
