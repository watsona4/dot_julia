using UnionFind

# edges must be pre-sorted according to weight.
function kruskal{T <: Integer}(nodes :: T, edges :: Array{(T, T)})
    uf = UnionFinder(nodes)
    mst = Array{(T, T)}

    for i in 1:length(edges)
        (u, v) = edges[i]
        if find!(uf, u) != find!(uf, v)
            union!(uf, u, v)
            push!(mst, (u, v))
        end
    end
end
