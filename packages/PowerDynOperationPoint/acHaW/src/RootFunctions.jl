# (C) 2018 authors and contributors (see AUTHORS file)
# Licensed under GNU GPL v3 (see LICENSE file)

using PowerDynBase: AbstractState, GridDynamics

"""
    struct RootFunction
        grid::GridDynamics
    end

Basic data structure providing a method to evalute a subtype of [`PowerDynBase.GridDynamics`](@ref) as
a right-hand-side function that can be used for root searching.
"""
struct RootFunction
    grid::GridDynamics
end
"""
    function (r::RootFunction)(x_out, x_in)

Evaluate the power grid dynamics of `r` for `x_in` and write it in `x_out`.
"""
function (r::RootFunction)(x_out, x_in)
    r.grid(x_out, x_in, 0., 0.)
end
function (r::RootFunction)(s_out::AbstractState{G, V, T}, s_in::AbstractState{G, V, T}) where {G, V, T}
    @assert GridDynamics(s_out) == @assert GridDynamics(s_in)
    r(s_out.base.vec, s_in.base.vec)
end
"""
    function (r::RootFunction)(x_in)

Evaluate the power grid dynamics of `r` for `x_in` and return the result.
"""
function (r::RootFunction)(x_in::AbstractVector)
    x_out = similar(x_in)
    r.grid(x_out, x_in, 0., 0.)
    x_out
end
function (r::RootFunction)(s::AbstractState{G, V, T}) where {G, V, T}
    State(GridDynamics(s), r(s.base.vec), t=s.t)
end
