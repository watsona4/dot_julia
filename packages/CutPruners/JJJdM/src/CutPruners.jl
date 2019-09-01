################################################################################
# CutPruners
# A package to manage polyhedral convex functions
################################################################################

VERSION < v"0.7.0-beta2.199" && __precompile__()

module CutPruners

using Compat, Compat.LinearAlgebra, Compat.SparseArrays
using MathProgBase

# Redudancy checking
include("redund.jl")

include("abstract.jl")
include("avg.jl")
include("decay.jl")
include("dematos.jl")
include("exact.jl")

end # module
