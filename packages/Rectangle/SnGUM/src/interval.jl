struct Interval{K}
    lo::K
    hi::K
    function Interval{K}(l::K, h::K) where {K}
        @assert !(h < l) "Invalid interval"
        new{K}(l, h)
    end
end

Interval(l::K, h::K) where K = Interval{K}(l, h)

Base.convert(::Type{Interval{K}}, t::Tuple{K, K}) where K = Interval(t...)

Base.promote_rule(::Type{Interval{T}}, ::Type{Interval{S}}) where {T, S} =
    Interval{promote_type(T, S)}

Base.show(io::IO, i::Interval) = Base.print(io, "($(i.lo), $(i.hi))")

function overlaps(i1::Interval{K}, i2::Interval{K}) where K
    (i1, i2) = i1.lo < i2.lo ? (i1, i2) : (i2, i1)
    return !(i2.lo < i1.lo) && !(i1.hi < i2.lo)
end

Base.isless(i1::Interval{K1}, i2::Interval{K2}) where {K1, K2} = 
    Base.isless(promote(i1, i2)...)

Base.isless(i1::Interval{K}, i2::Interval{K}) where {K} = 
    (i1.lo < i2.lo) || (!(i1.lo < i2.lo || i2.lo < i1.lo) && (i1.hi < i2.hi))

mutable struct IntervalKey{K}
    i::Interval{K}
    submax::K
    IntervalKey{K}(i::Interval{K}) where {K} = new{K}(i, i.hi)
end

Base.show(io::IO, k::IntervalKey) =
    print(io, "($(k.i.lo), $(k.i.hi), $(k.submax))")

IntervalKey(lo::K, hi::K) where {K} = IntervalKey{K}(Interval(lo, hi))
IntervalKey(i::Interval{K}) where {K} = IntervalKey(i.lo, i.hi)

const IntervalTree{K, V} = RBTree{IntervalKey{K}, V}
const IntervalNode{K, V} = RBNode{IntervalKey{K}, V}

Base.isless(i1::IntervalKey{K}, i2::IntervalKey{K}) where {K} =
    Base.isless(i1.i, i2.i)

function update_submax!(t::IntervalTree{K, V},
                        n::IntervalNode{K, V}) where {K, V}
    isnil(t, n)   && return
    isnil(t, n.l) && isnil(t, n.r) && (n.k.submax = n.k.i.hi; return)
    isnil(t, n.l) && (n.k.submax = max(n.k.i.hi, n.r.k.submax); return)
    isnil(t, n.r) && (n.k.submax = max(n.k.i.hi, n.l.k.submax); return)
    (n.k.submax = max(n.k.i.hi, n.l.k.submax, n.r.k.submax); return)
end

#=
Solution similar to as suggested here:

https://algs4.cs.princeton.edu/93intersection/
=#

@inline function _intersect(t::IntervalTree{K, V},
                            x::IntervalNode{K, V},
                            i::Interval{K},
                            nodes::Vector{IntervalNode{K, V}}) where {K, V}
    isnil(t, x) && return false
    lfound = !isnil(t, x.l) && !(x.l.k.submax < i.lo) &&
        _intersect(t, x.l, i, nodes)
    found = overlaps(i, x.k.i)
    found && push!(nodes, x)
    rfound = (lfound || isnil(t, x.l) || x.l.k.submax < i.lo) &&
        _intersect(t, x.r, i, nodes)
    return lfound || found || rfound
end

@inline function Base.intersect(t::IntervalTree{K, V},
                                i::Interval{K}) where {K, V}
    nodes = Vector{IntervalNode{K, V}}()
    _intersect(t, t.root, i, nodes)
    return [node.k.i => node.v for node in nodes]
end

@inline function intersects(t::IntervalTree{K, V}, i::Interval{K}) where {K, V}
    x = t.root
    while !isnil(t, x) && !overlaps(i, x.k.i)
        x = isnil(t, x.l) || (x.l.k.submax < i.lo) ? x.r : x.l
    end
    return !isnil(t, x)
end

_search(t::IntervalTree{K, V}, x::IntervalNode{K, V},
        i::Interval{K}) where {K, V} = _search(t, x, IntervalKey(i))

@inline function Base.get(t::IntervalTree{K, V},
                          i::Interval{K}, v::V) where {K, V}
    isempty(t) && return v
    n, d = _search(t, t.root, IntervalKey(i))
    d != 0 && return v
    return n.v
end

@inline function Base.get!(t::IntervalTree{K, V},
                           i::Interval{K}, v::V) where {K, V}
    if isempty(t)
        insert!(t, i, v)
        return v
    end
    n, d = _search(t, t.root, IntervalKey(i))
    d == 0 && return n.v
    insert!(t, i, v)
    return v
end

@inline function Base.setindex!(t::IntervalTree{K, V},
                                v::V, i::Interval{K}) where {K, V}
    if isempty(t)
        insert!(t, i, v)
        return v
    end
    n, d = _search(t, t.root, IntervalKey(i))
    d == 0 && delete!(t, i)
    insert!(t, i, v)
    return v
end

@inline function Base.getindex(t::IntervalTree{K, V},
                               i::Interval{K}) where {K, V}
    n, d = _search(t, t.root, IntervalKey(i))
    d != 0 && error("Index $i not found.")
    return n.v
end

@inline function left_rotate!(t::IntervalTree{K, V},
                              x::IntervalNode{K, V}) where {K, V}
    y = x.r
    x.r = y.l
    !isnil(t, y.l) && (y.l.p = x)
    y.p = x.p
    if isnil(t, x.p)
        t.root = y
    elseif x === x.p.l
        x.p.l = y
    else
        x.p.r = y
    end
    y.l = x
    x.p = y

    update_submax!(t, x)
    update_submax!(t, y)
    return 
end

@inline function right_rotate!(t::IntervalTree{K, V},
                               y::IntervalNode{K, V}) where {K, V}
    x = y.l
    y.l = x.r
    !isnil(t, x.r) && (x.r.p = y)
    x.p = y.p
    if isnil(t, y.p)
        t.root = x
    elseif y === y.p.r
        y.p.r = x
    else
        y.p.l = x
    end
    x.r = y
    y.p = x

    update_submax!(t, y)
    update_submax!(t, x)
    return 
end

function Base.insert!(t::IntervalTree{K, V},
                      k::IntervalKey{K},
                      v::V) where {K, V}
    z = RBNode(t, k, v)
    y = t.nil
    x = t.root

    while x !== t.nil
        y = x
        x = k < x.k ? x.l :
            !t.unique || (x.k < k) ? x.r :
            t.unique && error("Key $k already exists.")
    end
    z.p = y
    if y === t.nil
        t.root = z
    elseif k < y.k
        y.l = z
    else
        y.r = z
    end
    z.red = true
    zz = z
    # Ensure new node range is part of the tree subtree max calculations
    while !isnil(t, zz)
        update_submax!(t, zz)
        zz = zz.p
    end    
    _insert_fixup!(t, z)
    t.n += 1
    return t
end

function Base.insert!(t::IntervalTree{K, V}, lo::K, hi::K, v::V) where {K, V}
    ik = IntervalKey(lo, hi)
    Base.insert!(t, ik, v)
    return t
end

function Base.insert!(t::IntervalTree{K, V}, i::Interval{K}, v::V) where {K, V}
    ik = IntervalKey(i)
    Base.insert!(t, ik, v)
    return t
end

function Base.iterate(it::Iterator{IntervalKey{K}, V,
                                   IntervalTree{K, V}},
                      n::IntervalNode{K, V}) where {K, V}
    n === it.to && return nothing
    return ((n.k.i => n.v), _successor(n, it.tree))
end

Base.eltype(it::Iterator{IntervalKey{K}, V,
                         IntervalTree{K, V}}) where {K, V} = Pair{Interval{K}, V}

function Base.minimum(t::IntervalTree)
    isempty(t) && error("Empty tree cannot have a minimum")
    n = _minimum(t.root, t)
    return n.k.i => n.v
end

function Base.maximum(t::IntervalTree)
    isempty(t) && error("Empty tree cannot have a maximum")
    n = _maximum(t.root, t)
    return n.k.i => n.v
end

@inline function _delete!(t::IntervalTree{K, V},
                          z::IntervalNode{K, V}) where {K, V}
    y = z
    y_is_red = y.red
    if z.l === t.nil
        x = z.r
        _transplant!(t, z, z.r)
    elseif z.r === t.nil
        x = z.l
        _transplant!(t, z, z.l)
    else
        y = _minimum(z.r, t)
        y_is_red = y.red
        x = y.r
        if y.p === z
            x.p = y
        else
            _transplant!(t, y, y.r)
            y.r = z.r
            y.r.p = y
        end
        _transplant!(t, z, y)
        y.l = z.l
        y.l.p = y
        y.red = z.red
    end
    # Ensure that the delete of node is reflected up.
    tx = x
    while true
        update_submax!(t, tx)
        tx = tx.p
        isnil(t, tx) && break
    end    
    if !y_is_red
        _delete_fixup!(t, x)
    end
    return z
end

@inline function Base.delete!(t::IntervalTree{K, V}, i::Interval{K}) where {K, V}
    isempty(t) && error("Cannot delete from empty tree")
    n, d = _search(t, t.root, i)
    d != 0 && return nothing
    _delete!(t, n)
    t.n -= 1
    return n.k.i => n.v
end
