# (C) 2018 Potsdam Institute for Climate Impact Research, authors and contributors (see AUTHORS file)
# Licensed under GNU GPL v3 (see LICENSE file)

using DiffEqBase: DEProblem, RECOMPILE_BY_DEFAULT
using PowerDynBase: AbstractState, OrdinaryGridDynamics, OrdinaryGridDynamicsWithMass
using LinearAlgebra

const iipfunc = true # is in-place function

"""
    struct GridProblem{P<:DEProblem, S<:AbstractState, T<:AbstractFloat} # T is for the timespan
        prob::P
        start::S
        timespan::Tuple{T, T}
    end

Define an analogous problem to DifferentialEquations.jl's `DEProblem` subtypes.
In the future, this is planned to be replaced by a real `DEProblem` subtype.
"""
struct GridProblem{P<:DEProblem, S<:AbstractState, T<:AbstractFloat} # T is for the timespan
    prob::P
    start::S
    timespan::Tuple{T, T}
end

"""
    function GridProblem(start::AbstractState{OrdinaryGridDynamics, V, T}, timespan; kwargs...) where {V,T}

Construct a [`PowerDynSolve.GridProblem`](@ref) from a an initial condition (i.e. a [`PowerDynBase.State`](@ref)) for an
[`PowerDynBase.OrdinaryGridDynamics`](@ref).
"""
function GridProblem(start::AbstractState{OrdinaryGridDynamics, V, T}, timespan; kwargs...) where {V,T}
    GridProblem(ODEProblem{iipfunc}(GridDynamics(start), convert(AbstractVector{V}, start), timespan; kwargs...),
        start, timespan)
end

"""
    function GridProblem(start::AbstractState{OrdinaryGridDynamicsWithMass, V, T}, timespan; kwargs...) where {V,T}

Construct a [`PowerDynSolve.GridProblem`](@ref) from a an initial condition (i.e. a [`PowerDynBase.State`](@ref)) for an
[`PowerDynBase.OrdinaryGridDynamicsWithMass`](@ref).
"""
function GridProblem(start::AbstractState{OrdinaryGridDynamicsWithMass, V, T}, timespan; kwargs...) where {V,T}
    odefunc = ODEFunction{iipfunc, RECOMPILE_BY_DEFAULT}(GridDynamics(start), mass_matrix=( start |> NetworkRHS |> masses .|> Int |> Diagonal ))
    GridProblem(ODEProblem{iipfunc}(odefunc, convert(AbstractVector{V}, start), timespan; kwargs...),
        start, timespan)
end

"""
    function GridProblem(g::G, start::AbstractState{G, V, T}, timespan; kwargs...) where {G, V, T}

Construct a [`PowerDynSolve.GridProblem`](@ref) from a an initial condition `start` (i.e. a [`PowerDynBase.State`](@ref)) with the
corresponding subtype of [`PowerDynBase.GridDynamics`](@ref).
"""
function GridProblem(g::G, start::AbstractState{G, V, T}, timespan; kwargs...) where {G, V, T}
    @assert g === GridDynamics(start)
    GridProblem(start, timespan; kwargs...)
end


"""
    function GridProblem(g::GridDynamics, start::AbstractVector, timespan; kwargs...)

Construct a [`PowerDynSolve.GridProblem`](@ref) from a an initial condition `start` for the grid dynamics `g`
which is a subtype of [`PowerDynBase.GridDynamics`](@ref).
"""
function GridProblem(g::GridDynamics, start::AbstractVector, timespan; kwargs...)
    GridProblem(State(g, start), timespan)
end
