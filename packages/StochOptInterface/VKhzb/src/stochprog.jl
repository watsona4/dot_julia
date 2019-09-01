using LightGraphs

## Stochastic Program

"""
    AbstractStochasticProgram <: LightGraphs.AbstractGraph{Int}

Stochastic program instance.
"""
abstract type AbstractStochasticProgram <: LightGraphs.AbstractGraph{Int} end
if VERSION >= v"0.7-"
    Base.broadcastable(sp::AbstractStochasticProgram) = Ref(sp)
end

"""
    stochasticprogram(args...)

Create a stochastic program from the arguments.
"""
function stochasticprogram end

## Node

"""
    AbstractNode

Node instance.
"""
abstract type AbstractNode end

"""
    add_scenario_node!(sp::AbstractStochasticProgram, ...)

Add a new node to the stochastic program `sp` and returns it.
"""
function add_scenario_node! end

"""
    addcut!(sp::AbstractStochasticProgram, node,
            pool::SOI.AbstractSolutionPool, stats, ztol)

Add cut `cut` to the node `node` using the solution pool `pool` and the
threshold `ztol` to determine if the cut is redundant. The statistics are
recorded in `stats`.
"""
function addcut! end

"""
    applycuts!(sp::AbstractStochasticProgram, node)

Apply cuts additions to the node `node`.
"""
function applycuts! end

## Transition

"""
    AbstractTransition <: LightGraphs.AbstractEdge{Int}

Transition between two nodes of the stochastic program.
"""
abstract type AbstractTransition <: LightGraphs.AbstractEdge{Int} end

"""
    add_scenario_transition!(sp::AbstractStochasticProgram, ...)

Add a new transition to the stochastic program `sp` and returns it.
"""
function add_scenario_transition! end
