using SimilaritySearch
import SimilaritySearch: fit
using Random
export dnet


"""
A `k`-net is a set of points `M` such that each object in `X` can be:
- It is in `M`
- It is in the knn set of an object in `M` (defined with the distance function `dist`)

The size of `M` is determined by ``\\leftceil|X|/k\\rightceil``

The dnet function uses the `callback` function as an output mechanism. This function is called on each center as `callback(centerId, res)` where
res is a `KnnResult` object (from SimilaritySearch.jl).

"""
function dnet(callback::Function, dist::Function, X::Vector{T}, k) where {T}
    N = length(X)
    metadist = (a::Int, b::Int) -> dist(X[a], X[b])
    I = fit(Sequential, shuffle!(collect(1:N)))
    res = KnnResult(k)
    i = 0

    while length(I.db) > 0
        i += 1
        empty!(res)
        c = pop!(I.db)
        search(I, metadist, c, res)
        callback(c, res)
        @info "computing dnet point $i, dmax: $(covrad(res))"

        j = 0
        for p in res
            I.db[p.objID] = I.db[end-j]
            j += 1
        end

        for p in res
            pop!(I.db)
        end
    end
end
