module SemiDiscretizationMethod

using Reexport
@reexport using LinearAlgebra
@reexport using SparseArrays
@reexport using StaticArrays
@reexport using Arpack
using QuadGK
using Lazy: iterated, take

include("structures_method.jl")
include("structures_input.jl")
include("structures_result.jl")

include("functions_utility.jl")
include("functions_discretization.jl")
include("functions_method.jl")

export SemiDiscretization, NumericSD, 
ProportionalMX,
Delay,DelayMX,
Additive,
LDDEProblem,
DiscreteMapping, DiscreteMapping_1step,
fixPointOfMapping, spectralRadiusOfMapping

end # module
