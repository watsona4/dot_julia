# (C) 2018 Potsdam Institute for Climate Impact Research, authors and contributors (see AUTHORS file)
# Licensed under GNU GPL v3 (see LICENSE file)

__precompile__()

module PowerDynSolve

using OrdinaryDiffEq
using PowerDynBase
using Lazy: @>
using Parameters: @with_kw

# erros
include("Errors.jl")

# data types
const Time = Float64 # type fixed to avoid problems with DifferentialEquations.jl

include("TimeSpans.jl")
include("GridProblems.jl")
include("GridSolutions.jl")
include("CompositeGridSolution.jl")


# methods
include("solve.jl")

export solve, operationpoint, GridProblem, tspan, TimeSeries
export CompositeGridSolution
export realsolve, complexsolve


end # module PowerDynSolve
