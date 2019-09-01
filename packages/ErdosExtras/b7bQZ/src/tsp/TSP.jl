"""
    solve_tsp(g, w; cutoff=Inf)

Given a graph `g` and an edgemap `w` containing the weight associated to each edge,
solves the Travelling Salesman Problem, returning the tour among all the cities with
minimal total weight.

Edges `e` with no associated value in `w` or with `w[e] > cutoff`
will not be considered for the optimal tour.

The algorithm uses a generic Integer Programming solver combined with a lazy
constraint augmentation procedure.

The package JuMP.jl and one of its supported solvers are required.

Returns a tuple `(status, W, tour)` containing:
- a solve `status` (indicating whether the problem was solved to optimality)
- the tototal weight `W` of the tour
- a vector `tour` containing the sequence of vertices in the optimal tour.

**Example**
```julia
pos = rand(30, 2)
g = CompleteGraph(30)
w = EdgeMap(g, e -> norm(pos[src(e)] - pos[dst(e)]))
status, W, tour = solve_tsp(g, w)
```
"""
function solve_tsp(g::G, w::AEdgeMap; cutoff=Inf, verb=false) where G<:AGraph

    h = G(nv(g))
    for e in edges(g)
        haskey(w, e) && w[e] <= cutoff && add_edge!(h, e)
    end
    return _solve_tsp(h, w, verb)
end

function _solve_tsp(g::AGraph, w::AEdgeMap, verb::Bool)
    elist = collect(edges(g))

    model = Model(solver = MIP_SOLVER)
    @variable(model, y[elist], Bin)
    @objective(model, Min, sum(y[e]*w[e] for e in edges(g)))
    @constraint(model, c1[i=1:nv(g)], sum(y[sort(e)] for e in edges(g, i)) == 2)

    addlazycallback(model,
        cb -> begin
            sol = getvalue(y)
            alltours = gettours(g, sol)
            verb && println("Found $(length(alltours)) tours of lengths $(length.(alltours)). Adding lazy constraints.")
            for tour in alltours
                length(tour) == nv(g) && break
                add_tour_constraint(cb, y, g, tour)
            end
        end)

    status = solve(model)
    sol = getvalue(y)
    cost = getobjectivevalue(model)

    alltours = gettours(g, sol)
    @assert length(alltours) == 1 "Found $(length(alltours)) tours of lengths $(length.(alltours))."
    return status, cost, alltours[1]
end

function gettours(g, sol)
    TOL = 1e-8
    alltours = Vector{Vector{Int}}()
    notintour = [1:nv(g);]
    while !isempty(notintour)
        root = first(notintour)
        tour = Int[root]
        u  = root
        prev = -1
        while u != root || length(tour) == 1
            for e in out_edges(g, u)
                abs(sol[sort(e)]) < TOL && continue
                v = dst(e)
                v == prev && continue
                push!(tour, v)
                u, prev = v, u
                break
            end
        end
        resize!(tour, length(tour)-1)
        @assert length(tour) > 2
        notintour = setdiff(notintour, tour)
        @assert length(notintour) > 2 || length(notintour) == 0 "notintour=$notintour"
        push!(alltours, tour)
    end
    @assert sum(length.(alltours)) == nv(g)
    return alltours
end

function add_tour_constraint(cb, y, g, tour)
    aff = AffExpr()
    for (k, v) in enumerate(tour)
        vprev = k == 1 ? tour[end] : tour[k-1]
        vnext = k == length(tour) ? tour[1] : tour[k+1]
        for e in edges(g, v)
            if dst(e) ∉ [vprev,vnext]
                aff += y[sort(e)]
            end
        end
    end
    @lazyconstraint(cb, aff >= 2)
end
