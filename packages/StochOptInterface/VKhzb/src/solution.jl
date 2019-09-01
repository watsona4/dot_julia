# Solution at one node, different than Solution with is the full solution
abstract type AbstractSolution end

"""
    feasibility_cut(sol::AbstractSolution)

Return the tuple `(a, α)` representing the feasibility cut ``⟨a, x⟩ ≧ α``
certified by this solution.
"""
function feasibility_cut end

"""
    optimality_cut(sol::AbstractSolution)

Return the tuple `(a, α)` representing the optimality cut ``⟨a, x⟩ + θ ≧ α``
certified by this solution.
"""
function optimality_cut end

"""
    getstatus(sol::AbstractSolution)

Return the status of the solution `sol`.
"""
function getstatus end

"""
    getobjectivevalue(sol::AbstractSolution)

Return the objective value of the solution `sol` *including* the part of the
objective depending on Bellman value function `θ`.
"""
function getobjectivevalue end

"""
    getnodeobjectivevalue(sol::AbstractSolution)

Return the objective value of the solution `sol` *excluding* the part of the
objective depending on Bellman value function `θ`.
"""
function getnodeobjectivevalue end


"""
    getnodevalue(sol::AbstractSolution)

Return the value of the state of solution `sol`.
"""
function getnodevalue end

"""
    getbellmanvalue(sp::AbstractStochasticProgram, tr::AbstractTransition,
              sol::AbstractSolution)

Return the value of the Bellman function in the solution `sol` of node
`SOI.get(sp, SOI.Source(), tr)` for its transition `tr`.
This assumes that `node` is using `MultiCutGenerator`.

    getbellmanvalue(sp::AbstractStochasticProgram, node, sol::AbstractSolution)

Return the value of the Bellman function in the solution `sol` of node `node`.
This assumes that `node` is using `AvgCutGenerator`.
"""
function getbellmanvalue end

abstract type AbstractSolutionPool end

"""
    allfeasible(pool::AbstractSolutionPool)

Return a `Bool` indicating whether all transitions current solved were
feasible.
"""
function allfeasible end

"""
    allbounded(pool::AbstractSolutionPool)

Return a `Bool` indicating whether all transitions current solved were
bounded.
"""
function allbounded end

"""
    hassolution(pool::AbstractSolutionPool, tr::AbstractTransition)

Return a `Bool` indicating whether the solution pool `pool` has a solution for
transition `tr`.
"""
function hassolution end

"""
    getsolution(pool::AbstractSolutionPool)

Return the solution for the source of all the transitions.

    getsolution(pool::AbstractSolutionPool, tr::AbstractTransition)

Return the solution for transition `tr` in the solution pool `pool`.
"""
function getsolution end
