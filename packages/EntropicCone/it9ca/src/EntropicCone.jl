module EntropicCone

using LinearAlgebra
using SparseArrays

import MathProgBase
using Polyhedra

import Base.setindex!, Base.*, Base.show, Base.getindex, Base.setdiff, Base.union, Base.issubset, Base.promote_rule, Base.in, Base.-, Base.copy, Base.intersect

include("entropy.jl")
include("setmanip.jl")
include("vector.jl")
include("famousnsi.jl")
include("cone.jl")
include("conelift.jl")
include("coneoperations.jl")
include("conelp.jl")
#include("lphierarchy.jl")
#include("doughertylists.jl")
#include("visualize.jl")

end # module
