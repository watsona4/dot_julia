module Trajectories

export AbstractPairedArray, Trajectory, trajectory, issynchron
export interpolate, Linear, Left, Right
export piecewise

include("definitions.jl")
include("interpolate.jl")
include("piecewise.jl")
include("tables.jl")
include("recipe.jl")

end # module
