# (C) 2018 Potsdam Institute for Climate Impact Research, authors and contributors (see AUTHORS file)
# Licensed under GNU GPL v3 (see LICENSE file)

using PowerDynBase: AbstractState, OrdinaryGridDynamics, OrdinaryGridDynamicsWithMass

import DiffEqBase: solve

"""
    function solve(p::GridProblem; kwargs...)

Solve a [`PowerDynSolve.GridProblem`](@ref), using DifferentialEquations.jl in the back.
The correct solvers are automatically chosen.

`kwargs` are the keyword arguments that are simply passed to DifferentialEquations.jl.
"""
function solve(p::GridProblem{P, <:AbstractState{OrdinaryGridDynamics, V, T}, Q}; kwargs...) where {P, V, T, Q}
    GridSolution(solve(p.prob, Rodas4(); kwargs...), GridDynamics(p.start))
end

function solve(p::GridProblem{P, <:AbstractState{OrdinaryGridDynamicsWithMass, V, T}, Q}; kwargs...) where {P, V, T, Q}
    GridSolution(solve(p.prob, Rodas4(); kwargs...), GridDynamics(p.start))
end

function solve(p::GridProblem{P, <:AbstractState{G, V, T}, Q}; kwargs...) where {P, G, V, T, Q}
    throw(GridSolutionError("solve is not yet implemented for $G"))
    # GridSolution(solve(p.prob, Rodas4(); kwargs...), GridDynamics(p.start))
end

"""
    function solve(g::GridDynamics, x0, timespan)

Solve a power grid `g` (of type [`PowerDynSolve.GridDynamics`](@ref)) starting at `x0` for a `timespan`, using DifferentialEquations.jl in the back.
The correct solvers are automatically chosen.
"""
function solve(g::GridDynamics, x0, timespan)
    solve(GridProblem(g, x0, timespan))
end

realsolve(args...;t_res = 10_000) = begin
    @warn "`realsolve` has been deprecated in favor of `solve`"
    @> solve(args...) RealGridTimeseries(t_res=t_res)
end
complexsolve(args...;t_res = 10_000) = begin
    @warn "`complexsolve` has been deprecated in favor of `solve`"
    @> solve(args...) ComplexGridTimeseries(t_res=t_res)
end
