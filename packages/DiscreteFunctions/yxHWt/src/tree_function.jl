using DiscreteFunctions, SimpleGraphs

"""
`tree2function(T::SimpleGraph)` converts a tree `T` into a
`DiscreteFunction`. We assume the vertex set of `T` is of the
form `{1,2,...,n}`. The resulting function has each vertex pointing
to the next vertex on a path to the vertex `1`.

**Warning**: I don't check if the input graph is valid. That is
it *must* be a tree with vertex set `1:n`.
"""
function tree2function(G::SimpleGraph)::DiscreteFunction
    n = NV(G)
    data = zeros(Int,n)
    data[1] = 1
    for v = 2:n
        P = find_path(G,v,1)
        data[v] = P[2]
    end
    return DiscreteFunction(data)
end
