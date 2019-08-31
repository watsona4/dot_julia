module BernoulliFactory

using Random

## TODO: move this to NonUniformRandomVariateGeneration
@inline function _sampleGeometric(p::Float64, rng::RNG) where RNG<:AbstractRNG
  return floor(Int64, randexp(rng)/(-log(1.0-p)))+1
end

include("huber2016.jl")
include("huber2017.jl")
include("wastlundSqrt.jl")
include("mendoPower.jl")
include("algorithms.jl")
include("signedEstimate.jl")

end # module
