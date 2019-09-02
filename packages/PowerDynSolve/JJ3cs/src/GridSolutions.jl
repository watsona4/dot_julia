# (C) 2018 Potsdam Institute for Climate Impact Research, authors and contributors (see AUTHORS file)
# Licensed under GNU GPL v3 (see LICENSE file)

using Lazy
using DiffEqBase: AbstractTimeseriesSolution
using PowerDynBase
import PowerDynBase: GridDynamics, internalindex

"Abstract super type for all data structures representing solutions of power grid models."
abstract type AbstractGridSolution end

abstract type AbstractSingleGridSolutions <: AbstractGridSolution end

 # to ensure broadcasting can be used
 @inline Broadcast.broadcastable(sol::AbstractSingleGridSolutions) = Ref(sol)
"""
    struct GridSolution <: AbstractSingleGridSolutions
        dqsol::AbstractTimeseriesSolution
        griddynamics::GridDynamics
    end

The data structure interfacing to the solution of the differntial equations of a power grid.
Normally, it is not created by hand but return from `PowerDynSolve.solve`.

# Accessing the solution in a similar interface as [`PowerDynBase.State`](@ref).

For some grid solution `sol`, one can access the variables as
```julia
sol(t, n, s)
```
where `t` is the time (either float or array),
`n` the node number(s) (either integer, array, range (e.g. 2:3) or colon (:, for all nodes)),
and `s` is the symbol represnting the chosen value.
`s` can be either: `:v`, `:φ`, `:i`, `:iabs`, `:δ`, `:s`, `:p`, `:q`, or the symbol of the internal variable of the nodes.
The meaning of the symbols derives from the conventions of PowerDynamics.jl.

Finally, one can access the `a`-th internal variable of a node by using `sol(t, n, :int, a)`.

# Interfacing the Plots.jl library via plotting recipes, that follow similar instructions as the direct access to the solution.

For some grid solution `sol`, one plot variables of the solution asin
```julia
using Plots
plot(sol, n, s, plots_kwargs...)
```
where `n` and `s` are as in the accessing of plots, and `plots_kwargs` are the keyword arguments for Plots.jl.
"""
struct GridSolution <: AbstractSingleGridSolutions
    dqsol::AbstractTimeseriesSolution
    griddynamics::GridDynamics
    function GridSolution(dqsol::AbstractTimeseriesSolution, griddynamics::GridDynamics)
        if dqsol.retcode != :Success
            throw(GridSolutionError("unsuccesful, return code is $(dqsol.retcode)"))
        end
        new(dqsol, griddynamics)
    end
end
GridDynamics(sol::GridSolution) = sol.griddynamics
TimeSeries(sol::GridSolution) = sol.dqsol
tspan(sol::GridSolution) = (TimeSeries(sol).t[1], TimeSeries(sol).t[end])
tspan(sol::GridSolution, tres) = range(TimeSeries(sol).t[1], stop=TimeSeries(sol).t[end], length=tres)

(sol::GridSolution)(sym::Symbol) = sol(Val{sym})
(sol::GridSolution)(::Type{Val{:initial}}) = sol(tspan(sol)[1])
(sol::GridSolution)(::Type{Val{:final}}) = sol(tspan(sol)[2])
(sol::GridSolution)(t::Number) = begin
    t = convert(Time, t)
    State(GridDynamics(sol), convert(Array, TimeSeries(sol)(t)), t=t)
end

(sol::GridSolution)(t, ::Colon, sym::Symbol, args...; kwargs...) = sol(t, eachindex(Nodes(sol)), sym, args...; kwargs...)
(sol::GridSolution)(t, n, sym::Symbol, args...) = begin
    if ~all( 1 .<= n .<= length(Nodes(sol)) )
        throw(BoundsError(sol, n))
    else
        sol(t, n, Val{sym}, args...)
    end
end
(sol::GridSolution)(t::Number, n::Number, ::Type{Val{:u}}) = begin
    u_real = TimeSeries(sol)(t, idxs= 2 * n - 1)
    u_imag = TimeSeries(sol)(t, idxs= 2 * n)
    u_real + im * u_imag
end
(sol::GridSolution)(t, n, ::Type{Val{:u}}) = begin
    u_real = @>> TimeSeries(sol)(t, idxs= 2 .* n .- 1) convert(Array)
    u_imag = @>> TimeSeries(sol)(t, idxs= 2 .* n) convert(Array)
    u_real .+ im .* u_imag
end
(sol::GridSolution)(t, n, ::Type{Val{:v}}) = sol(t, n, :u) .|> abs
(sol::GridSolution)(t, n, ::Type{Val{:φ}}) = sol(t, n, :u) .|> angle
(sol::GridSolution)(t, n, ::Type{Val{:i}}) = (AdmittanceLaplacian(sol) * sol(t, :, :u))[n, :]
(sol::GridSolution)(t::Number, n, ::Type{Val{:i}}) = (AdmittanceLaplacian(sol) * sol(t, :, :u))[n]
(sol::GridSolution)(t, n, ::Type{Val{:iabs}}) = sol(t, n, :i) .|> abs
(sol::GridSolution)(t, n, ::Type{Val{:δ}}) = sol(t, n, :i) .|> angle
(sol::GridSolution)(t, n, ::Type{Val{:s}}) = sol(t, n, :u) .* conj.(sol(t, n, :i))
(sol::GridSolution)(t, n, ::Type{Val{:p}}) = sol(t, n, :s) .|> real
(sol::GridSolution)(t, n, ::Type{Val{:q}}) = sol(t, n, :s) .|> imag
(sol::GridSolution)(t, n, ::Type{Val{:int}}, i) = @>> TimeSeries(sol)(t, idxs=internalindex(sol, n, i)) convert(Array)
(sol::GridSolution)(t::Number, n::Number, ::Type{Val{:int}}, i::S) where {S <: Union{Number,Symbol}} = TimeSeries(sol)(t, idxs=internalindex(sol, n, i))
(sol::GridSolution)(t, n, ::Type{Val{sym}}) where sym = sol(t, n, Val{:int}, sym)

# define the plotting recipes
using RecipesBase

"Create the standard variable labels for power grid plots."
tslabel(sym, node) = "$(sym)$(node)"
"Transform the array output from DifferentialEquations.jl correctly to be used in Plots.jl's recipes."
tstransform(arr::AbstractArray{T, 1}) where T = arr
tstransform(arr::AbstractArray{T, 2}) where T = arr'

const PLOT_TTIME_RESOLUTION = 1_000

@recipe function f(sol::AbstractSingleGridSolutions, ::Colon, sym::Symbol, args...)
    sol, eachindex(Nodes(sol)), sym, args...
end

function getPlottingData(sol::AbstractSingleGridSolutions, n, sym::Symbol, args...; tres)
    t = tspan(sol, tres)
    t, tstransform(sol(t, n, sym, args...))
end

@recipe function f(sol::AbstractSingleGridSolutions, n, sym::Symbol, args...; tres = PLOT_TTIME_RESOLUTION)
    if sym == :int
        throw(PowerDynamicsPlottingError("deprecated usage of `:int` for indexing the internal variables: cannot be used for plotting. Use the symbol representing the internal variables instead, e.g. `:ω` for `SwingEq`."))
    end
    label --> tslabel.(sym, n)
    xlabel --> "t"
    t = tspan(sol, tres)
    t, tstransform(sol(t, n, sym, args...))
    getPlottingData(sol, n, sym, args...; tres = tres)
end
