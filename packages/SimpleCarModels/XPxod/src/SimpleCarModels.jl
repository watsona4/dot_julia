module SimpleCarModels

using StaticArrays
using DifferentialDynamicsModels
using SpecialFunctions
import DifferentialDynamicsModels: mod2piF, adiff

include("math.jl")
include("models.jl")
include("dubins.jl")
include("reedsshepp.jl")
include("dubinsCC.jl")
include("elementary.jl")

end # module
