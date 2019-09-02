module MaximumLikelihoodPower

"""
    module MaximumLikelihoodPower

Maximum likelihood calculations for power laws.

Functions: mle, KStatistic, scanmle, scanKS
"""
MaximumLikelihoodPower

export mle, KSstatistic, scanmle, scanKS, mleKS

include("mle.jl")
include("aux.jl")

end # module
