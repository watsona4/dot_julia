VERSION < v"0.7-" && __precompile__()

module SMCExamples

using SequentialMonteCarlo
using RNGPool
using StaticArrays

import Compat.UndefInitializer
if VERSION < v"0.7-"
  MVector{d, Float64}(::UndefInitializer) where d = MVector{d, Float64}()
  MMatrix{d, d, Float64}(::UndefInitializer) where d = MMatrix{d, d, Float64}()
end

include("particles.jl")
include("lgModel.jl")
include("mvlgModel.jl")
include("smcSampler.jl")
include("finiteFK.jl")
include("nettoModel.jl")
include("lorenz96Model.jl")

end # module
