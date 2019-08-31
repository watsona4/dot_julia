module NonUniformRandomVariateGeneration

using Random
import Random.GLOBAL_RNG

include("binomial.jl")
include("multinomial.jl")
include("poisson.jl")
include("gamma.jl")
include("beta.jl")
include("uniform.jl")
include("categorical.jl")

export sampleBinomial, sampleMultinomial, sampleMultinomial!, sampleGamma,
  sampleBeta, samplePoisson, sampleSortedUniforms!, sampleSortedUniforms,
  sampleCategorical, sampleCategoricalSorted, sampleCategoricalSorted!

end
