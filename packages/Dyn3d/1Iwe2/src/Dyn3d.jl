__precompile__()

module Dyn3d

using Reexport
using DocStringExtensions

include("config_files/ConfigDataType.jl")
@reexport using .ConfigDataType

include("Utils.jl")
@reexport using .Utils

include("SpatialAlgebra.jl")
@reexport using .SpatialAlgebra

include("ConstructSystem.jl")
@reexport using .ConstructSystem

include("UpdateSystem.jl")
@reexport using .UpdateSystem

include("RigidBodyDynamics.jl")
@reexport using .RigidBodyDynamics

include("TimeMarching.jl")
@reexport using .TimeMarching

include("FluidInteraction.jl")
@reexport using .FluidInteraction

end
