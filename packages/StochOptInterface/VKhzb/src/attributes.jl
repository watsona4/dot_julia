# Attributes

"""
    AbstractStochasticProgramAttribute

Abstract supertype for attribute objects that can be used to set or get
attributes (properties) of the stochastic program.
"""
abstract type AbstractStochasticProgramAttribute end

"""
    AbstractNodeAttribute

Abstract supertype for attribute objects that can be used to set or get
attributes (properties) of nodes in the stochastic program.
"""
abstract type AbstractNodeAttribute end

"""
    AbstractTransitionAttribute

Abstract supertype for attribute objects that can be used to set or get
attributes (properties) of transitions in the stochastic program.
"""
abstract type AbstractTransitionAttribute end

if VERSION >= v"0.7-"
    Base.broadcastable(attr::Union{AbstractStochasticProgramAttribute,
                                   AbstractNodeAttribute,
                                   AbstractTransitionAttribute}) = Ref(attr)
end

"""
    get(sp::AbstractStochasticProgram, attr::AbstractStochasticProgramAttribute)

Return an attribute `attr` of the stochastic program `sp`.

    get(sp::AbstractStochasticProgram, attr::AbstractNodeAttribute, node)

Return an attribute `attr` of the node `node` in stochastic program `sp`.

    get(sp::AbstractStochasticProgram, attr::AbstractTransitionAttribute,
        tr::AbstractTransition)

Return an attribute `attr` of the transition `tr` in stochastic program `sp`.

### Examples

```julia
get(model, MasterNode())
get(model, Solution(), node)
get(model, Probability(), tr)
```
"""
function get end

"""
    set!(sp::AbstractStochasticProgram,
         attr::AbstractStochasticProgramAttribute, value)

Assign `value` to the attribute `attr` of the stochastic program `sp`.

    set!(sp::AbstractStochasticProgram, attr::AbstractNodeAttribute, node,
         value)

Assign `value` to the attribute `attr` of the node `node` in stochastic
program `sp`.

    set!(sp::AbstractStochasticProgram, attr::AbstractTransitionAttribute,
         tr::AbstractTransition, value)

Assign `value` to the attribute `attr` of the transition `tr` in stochastic
program `sp`.

### Examples

```julia
set!(model, CutGenerator(), node, cutgen)
set!(model, SourceSolution(), tr, sol)
```
"""
function set! end

## Stochastic Program attributes

"""
    MasterNode <: AbstractStochasticProgramAttribute

The master node.
"""
struct MasterNode <: AbstractStochasticProgramAttribute end

"""
    TransitionType <: AbstractStochasticProgramAttribute

The type of the transitions, i.e.
    `typeof(first(get(sp, OutTransitions(), node)))`.
"""
struct TransitionType <: AbstractStochasticProgramAttribute end

"""
    NumberOfStages <: AbstractStochasticProgramAttribute

The number of stages of the stochastic program.
A path starting from the master node of length equal to the number of stages
does not necessarily have to end with a node with no outgoing edges.
The stochastic program can even contain infinite paths and `NumberOfStages` is
used to truncate the exploration.
"""
struct NumberOfStages <: AbstractStochasticProgramAttribute end

"""
    struct NumberOfPaths <: AbstractStochasticProgramAttribute
        length::Int
    end

The number of paths of length `length` starting from the master node.
"""
struct NumberOfPaths <: AbstractStochasticProgramAttribute
    length::Int
end
function get(sp::AbstractStochasticProgram, nop::NumberOfPaths)
    get(sp, NumberOfPathsFrom(nop.length), get(sp, MasterNode()))
end

## Node attributes

# Graph-related
"""
    struct OutTransitions

The outgoing transitions from the node.
"""
struct OutTransitions <: AbstractNodeAttribute end

# May be different from the number of out-neighbors if there are multiple
# transitions with the same target
function LightGraphs.outdegree(sp::AbstractStochasticProgram, node::Int)
    length(get(sp, OutTransitions(), node))
end

"""
    struct NumberOfPathsFrom <: AbstractNodeAttribute
        length::Int
    end

The number of paths of length `length` starting from the node.
"""
struct NumberOfPathsFrom <: AbstractNodeAttribute
    length::Int
end

# Optimization-related
"""
    Solution <: AbstractNodeAttribute

The solution at the node.
"""
struct Solution <: AbstractNodeAttribute end

"""
    Dimension <: AbstractNodeAttribute

The number of variables of the stochastic program at the node (not including
the auxiliary variables used for the objective value of its outgoing transitions.
"""
struct Dimension <: AbstractNodeAttribute end

"""
    NeedAllSolutions <: AbstractNodeAttribute

A `Bool` indicating whether the node needs all solutions in the solution pool
in order to generate an optimality cut.
"""
struct NeedAllSolutions <: AbstractNodeAttribute end

"""
    NodeObjectiveValueBound <: AbstractNodeAttribute

The current bound to the objective of the node.

### Examples

If the program at node `node` is bounded and the objective value of its
outgoing transtitions is bounded too (e.g. `TransitionObjectiveValueBound`
has been set to a finite value), `MOI.get(sp, node)` returns a finite value
summing.
"""
struct NodeObjectiveValueBound <: AbstractNodeAttribute end

## Transition attributes

"""
    Source <: AbstractTransitionAttribute

The source of the transition.
"""
struct Source <: AbstractTransitionAttribute end

"""
    Target <: AbstractTransitionAttribute

The target of the transition.
"""
struct Target <: AbstractTransitionAttribute end

"""
    Probability <: AbstractTransitionAttribute

The probability of the transition.
"""
struct Probability <: AbstractTransitionAttribute end

"""
    SourceSolution <: AbstractTransitionAttribute

The solution of the source of a transition to be used by its destination.
"""
struct SourceSolution <: AbstractTransitionAttribute end

"""
    TransitionObjectiveValueBound <: AbstractNodeAttribute

The current bound to the objective of the node.
"""
struct TransitionObjectiveValueBound <: AbstractNodeAttribute end
