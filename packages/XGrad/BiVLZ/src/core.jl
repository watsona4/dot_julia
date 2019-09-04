using LinearAlgebra
using Espresso
import Espresso: @get, @get_or_create,
    genname, to_context, subs_bcast_with_dot,
    assign_chain


include("utils.jl")
include("rules.jl")
include("deriv.jl")
include("xdiff.jl")
include("xgrad0.jl")
include("helpers.jl")
include("debug.jl")
