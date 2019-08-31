# `CompressedFinder{T <: Integer}` is an optimized variant of UnionFinder{T}
# which does not support the addition of more edges. `CompressedFinder` also
# tracks the number of groups in the graph and garuantees that all group IDs
# will be between 1 and the total group number, inclusive.
mutable struct CompressedFinder{T <: Integer}
    ids :: Vector{T}
    groups :: T

    # `CompressedFinder(uf)` creates a `CompressedFinder` instance from the 
    # groups within `uf`.
    function CompressedFinder{T}(uf :: UnionFinder{T}) where T
        groups = zero(T)
        ids = zeros(T, length(uf.parents))
        
        for i in one(T):convert(T, length(uf.parents))
            root = find!(uf, i)
            if ids[root] == 0
                groups += 1
                ids[root] = groups
            end
            ids[i] = ids[root]
        end
        
        return new(ids, convert(T, groups))
    end
end


CompressedFinder(uf :: UnionFinder) = CompressedFinder{eltype(uf.sizes)}(uf)


# `find(cf, node)` returns the group ID of `node`. `node` must be a valid
# index into `uf`.
function find(cf :: CompressedFinder{T}, node :: T) where T <: Integer
    if node <= 0 || node > length(cf.ids)
        throw(BoundsError())
    end

    return cf.ids[node]
end


# `length(cf)` returns the number of nodes in `cf`.
function Base.length(cf :: CompressedFinder)
    return length(cf.ids)
end


# `groups(cf)` returns the number of groups in `cf`.
function groups(cf :: CompressedFinder)
    return cf.groups
end
