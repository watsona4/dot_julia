
"""
    dfs(digraph, start_node, visitor)

Depth-first search starting from `start_node`. The signature of `visitor` should
be `(prev::Int, curr::Int) -> Union{Bool, Void}`. If visitor returns
(optionally) `false`, then `dfs` stops.

# Examples
```
dg = Digraph()
n1 = add_node!(dg)
n2 = add_node!(dg)
n3 = add_node!(dg)
n4 = add_node!(dg)
add_edge!(dg, n1, n2)
add_edge!(dg, n2, n3)
add_edge!(dg, n1, n4)
order = []
function visitor(p, c)
    push!(order, c)
end
dfs(dg, n1, visitor)
```
"""
function dfs(dg::Digraph, start::Integer, visitor::Function)
    visited = fill(false, node_count(dg))
    dfs_rec(dg, Int(start), visitor, Int(0), visited)
end

export dfs

function dfs_rec(dg::Digraph, curr::Int, visitor::Function, prev::Int, visited::Vector{Bool})
    res = visitor(prev, curr)
    cont::Bool = true
    if isa(res, Bool)
        cont = res
    end
    visited[curr] = true
    if cont
        for eid in out_edges(dg, curr)
            dst = dst_node(dg, eid)
            if !visited[dst]
                cont = dfs_rec(dg, dst, visitor, curr, visited)
                if !cont
                    break
                end
            end
        end
    end
    return cont
end
