"""
    minimum_weight_perfect_bmatching(g, b[, w]; cutoff=Inf)

Given a graph `g` and an edgemap `w` containing the weight associated to each edge,
returns the perfect `b`-matching with the minimum total weight.

A perfect `b`-matching `M` is a collection of edges in `g` such that every vertex
has exactly `b` incident edges in `M` .

If `w` is not given, all edges will be considered to have weight one
(results in max cardinality b-matching).

Edges `e` with no associated value in `w` or with `w[e] > cutoff`
will not be considered for the matching.

The algorithm uses Linear Programming to solve the linear relaxation of the
problem first, then eventually refines the solution with an Integer Programming solver.

The efficiency of the algorithm depends on the input graph:
- If the graph is bipartite, then the LP relaxation is integral.
- If the graph is not bipartite, then an IP may be required to refine the solution
 and the computation time may grow exponentially.

The package JuMP.jl and one of its supported solvers are required.

Returns a tuple `(status, W, match)` containing:
- a solve `status` (indicating whether the problem was solved to optimality)
- the tototal weight `W` of the matching
- a vector of vectors `match`, where `match[v]`  contains  the `b` neighbors of `v` in the optimal matching.

**Example**
```juliarepl
julia> g = CompleteGraph(30)
julia> w = EdgeMap(g, e -> rand())
julia> status, W, match = minimum_weight_perfect_bmatching(g, 2, w)
```
"""
function minimum_weight_perfect_bmatching(g::G, b::Integer,
                w::AEdgeMap=ConstEdgeMap(g,1); cutoff=Inf, verb=true) where G<:AGraph 
        h = G(nv(g))
        for e in edges(g)
            haskey(w, e) && w[e] <= cutoff && add_edge!(h, e)
        end

        return _solve_bmatching(h, b, w, verb)
end

function _solve_bmatching(g::AGraph, b, w, verb)
    elist = collect(edges(g))

    ## Linear Programming
    # model = Model(solver=LP_SOLVER)
    # @variable(model, 0 <= x[elist] <= 1)
    # @objective(model, Max, sum(x[e]*w[e] for e in elist))
    # @constraint(model, c1[i=1:nv(g)], sum(x[sort(e)] for e in edges(g, i)) == b)
    # status = solve(model)
    # sol = getvalue(x)
    # cost = getobjectivevalue(model)
    # isintegral(sol, verb) && return status, cost, mates(nv(g), b, sol)
    # verb && warn("Using Integer Programming.")

    ## Integer Programming
    model = Model(solver = MIP_SOLVER)

    @variable(model, y[elist], Bin)
    @objective(model, Min, sum(y[e]*w[e] for e in elist))
    @constraint(model, c[i=1:nv(g)], sum(y[sort(e)] for e in edges(g, i)) == b)

    # Bootstrap from LP
    # for e in elist
    #     setvalue(y[e], round(Int, getvalue(x[e])))
    # end

    status = solve(model)
    sol = getvalue(y)
    cost = getobjectivevalue(model)

    return status, cost, mates(g, b, sol)
end

function isintegral(sol, verb)
    TOL = 1e-8
    f(x) = abs(x - round(Int, x)) > TOL
    n = count(f(sol[e]) for (e,) in keys(sol))
    verb && n > 0 && warn("$n non integer variables out of $(length(sol)) in linear relaxation.")
    return n == 0
end

function mates(g, b, sol)
    TOL = 1e-8
    n = nv(g)
    mate = [sizehint!(zeros(Int, 0), b) for i=1:n]
    for e in edges(g)
        sol[e] == 0 && continue
        if abs(sol[e] - 1) < TOL
            push!(mate[src(e)], dst(e))
            push!(mate[dst(e)], src(e))
        end
    end
    for v in mate
        @assert length(v) == b
        sort!(v)
    end
    return mate
end
