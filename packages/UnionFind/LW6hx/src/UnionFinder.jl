# `UnionFinder{T <: Integer}` is a graph containing a constant number of nodes
# which allows for union-find operations. All nodes are indexed by an integer
# of type `T` which is between 1 an the number of internal nodes.
mutable struct UnionFinder{T <: Integer}
    sizes :: Vector{T}
    parents :: Vector{T}

    # `UnionFinder(nodes)` returns a `UnionFinder` with `nodes` unconnected
    # internal nodes.
    function UnionFinder{T}(nodes :: T) where T
        if nodes <= 0
            throw(ArgumentError("Non-positive nodes, $nodes."))
        end
        
        uf = new(Vector{T}(undef, Int(nodes)), Vector{T}(undef, Int(nodes)))
        reset!(uf)
        
        return uf
    end
end

UnionFinder(nodes :: Integer) = UnionFinder{typeof(nodes)}(nodes)

# `reset(uf)` disconnects all the nodes within `uf`.
function reset!(uf :: UnionFinder)
    for i in 1:length(uf.parents)
        uf.sizes[i] = 1
        uf.parents[i] = i
    end
end


# `union!(uf, iterator)` iterates through `iterator` which returns integer
# edges, (`u`, `v`), and connects them within `uf`. `u` and `v` must be valid
# node indices for `uf`.
function union!(uf :: UnionFinder{T}, iterator) where T <: Integer
    for (u, v) in iterator
        union!(uf, u, v)
    end
end


# `union!(uf, us, vs)` connects nodes within `uf` which are bridged by
# the edges (`us[i]`, `vs[i]`). All values in `us` and `vs` must be valid node
# indices for `uf` and `us` and `vs` must be the same length.
function union!(uf :: UnionFinder{T},
                us :: Vector{T}, vs :: Vector{T}) where T <: Integer
    if length(us) != length(vs)
        throw(ArgumentError("us and vs not of the same length."))
    end

    for i in 1:length(us)
        union!(uf, us[i], vs[i])
    end
end


# `union!(uf, edges)` conncts all nodes within `uf` which are bridged by an
# edge within `edges`. Both vertices for each edge must be valid node indices
# into `uf`.
function union!(uf :: UnionFinder{T},
                edges :: Vector{Tuple{T,T}}) where T <: Integer
    for (u, v) in edges
        union!(uf, u, v)
    end
end


# `union!(uf, node1, node2)` connects the nodes within `uf` with indices
# `node1` and `node2`. `node1` and `node2` must be valid indices into `uf`.
function union!(uf :: UnionFinder{T}, node1 :: T, node2 :: T) where T <: Integer
    root1 = find!(uf, node1)
    root2 = find!(uf, node2)

    # TODO: Test whether using rank or using size is better for performance.
    if root1 == root2
        return
    elseif uf.sizes[root1] < uf.sizes[root2]
        uf.parents[root1] = root2
        uf.sizes[root2] += uf.sizes[root1]
    else
        uf.parents[root2] = root1
        uf.sizes[root1] += uf.sizes[root2]
    end
end


# `find!(uf, node)` returns the group ID of `node`. `node` must be a valid
# index into `uf`.
function find!(uf :: UnionFinder{T}, node :: T) where T <: Integer
    if node > length(uf.parents) || node <= 0
        throw(BoundsError())
    end
    if uf.parents[node] != uf.parents[uf.parents[node]]
        compress!(uf, node)
    end
    return uf.parents[node]
end


# `compress(uf, node)` compresses the internal parental node tree so that
# all nodes between `node` and the root of its group will point directly to the
# root. `node` must be a valid index into `uf`.
#
# Not publicly exported.
function compress!(uf :: UnionFinder{T}, node :: T) where T <: Integer
    child = node
    parent = uf.parents[child]

    while child != parent
        child = parent
        parent = uf.parents[child]
    end
    root = child

    child = node
    parent = uf.parents[child]
    uf.parents[child] = root

    while child != parent
        child = parent
        parent = uf.parents[child]
        uf.parents[child] = root
    end
end


# `length(uf)` returns the number of nodes in `uf`.
function Base.length(uf :: UnionFinder)
    return length(uf.parents)
end


# `size!(uf, node)` returns the size of the group containing `node`.
function size!(uf :: UnionFinder{T}, node :: T) where T <: Integer
    return uf.sizes[find!(uf, node)]
end
