__precompile__(true)

module Discreet

using StatsBase
using Compat
import Compat.sum

export
    entropy,
    estimate_entropy,
    estimate_joint_entropy,
    mutual_information_contingency,
    mutual_information

### Source files
include("entropy.jl")
include("mutual_information.jl")

end # module
