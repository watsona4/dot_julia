using OffsetArrays: OffsetArray

# replace first entries in a by b
merge_tups(a::Tuple, b) = merge_tups(a, to_tuple(b)::Tuple)
merge_tups(a::Tuple, ::Tuple{}) = a
merge_tups(a::Tuple, b::Tuple) = (first(b), merge_tups(Base.tail(a), Base.tail(b))...)

# only take first few entries of a so that result is as long as b
cut_tup(a::Tuple, b) = cut_tup(a, to_tuple(b)::Tuple)
cut_tup(a::Tuple, ::Tuple{}) = ()
cut_tup(a::Tuple, b::Tuple) = (first(a), cut_tup(Base.tail(a), Base.tail(b))...)

to_indexarray(t::Tuple{AbstractArray}) = t[1]
to_indexarray(t::Tuple{AbstractArray, Vararg{AbstractArray}}) = CartesianIndices(t)

_view(a::AbstractArray{<:Any, M}, b::AbstractArray{<:Any, N}) where {M, N} = view(a, b, ntuple(_ -> :, M-N)...)
_view(a::AbstractArray{<:Any, N}, b::AbstractArray{<:Any, N}) where {N} = view(a, b)

offsetrange(v, offset, range=()) = offsetrange(v, to_tuple(offset)::Tuple, to_tuple(range)::Tuple)

function offsetrange(v, offset::Tuple, range::Tuple=())
    short_axes = cut_tup(axes(v), offset)
    padded_range = merge_tups(short_axes, range)
    rel_offset = map(short_axes, offset, padded_range) do ax, off, r
        - off + first(r) - first(ax)
    end
    OffsetArray(to_indexarray(padded_range), rel_offset)
end

aroundindex(v, args...) = _view(v, offsetrange(v, args...))

function initstats(stat, ranges)
    ranges = to_tuple(ranges)
    itr = Iterators.product(ranges...)
    vec = [copy(stat) for _ in itr]
    return OffsetArray(vec, ranges)
end

# TODO combine fititer! and fitvec!
function fitvec!(m, val, shared_indices = eachindex(m, val))
    for cart in shared_indices
        @inbounds fit!(m[cart], val[cart])
    end
    return m
end

function fitvecmany!(m, iter)
    for el in iter
        am, ael = axes(m), axes(el)
        shared = (am == ael) ? eachindex(m, el) : CartesianIndices(map(intersect, am, ael))
        fitvec!(m, el, shared)
    end
    return m
end
