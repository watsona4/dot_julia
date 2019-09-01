"""
    EffectSizes

A Julia package for effect size measures.
"""
module EffectSizes

export
    EffectSize,
    CohenD,
    HedgeG,
    GlassΔ,
    effectsize,
    confint,
    lower,
    upper,
    quantile

import Statistics: mean, std
import Distributions
import Distributions: quantile, Normal
import HypothesisTests
import HypothesisTests: confint
import Base.Grisu: PRECISION

include("confint.jl")
include("effectsize.jl")

"""
    const EffectSize = CohenD

See [`CohenD`](@ref).
"""
const EffectSize = CohenD

end # module
