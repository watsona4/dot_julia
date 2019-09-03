module SortedVectors

export SortedVector

using ArgCheck: @argcheck
using DocStringExtensions: SIGNATURES
using Lazy: @forward
using Parameters: @unpack

"""
Flag for indicating that

1. sorting should be verified,
2. the argument vector will not be modified later.

Not exported.
"""
struct CheckSorted end

"""
Flag for indicating that

1. the argument should be assumed to be sorted, and **this should not be checked**,
2. the argument vector will not be modified later.

Not exported.
"""
struct AssumeSorted end

struct SortedVector{T, F, V <: AbstractVector{T}} <: AbstractVector{T}
    "comparison function for sorting"
    lt::F
    "sorted contents"
    sorted_contents::V
    function SortedVector(::AssumeSorted, lt::F,
                          sorted_contents::V) where {F, V <: AbstractVector}
        new{eltype(sorted_contents), F, V}(lt, sorted_contents)
    end
end

function SortedVector(::CheckSorted, lt, sorted_contents::AbstractVector)
    @argcheck issorted(sorted_contents; lt = lt)
    SortedVector(AssumeSorted(), lt, sorted_contents)
end

"""
    SortedVector([lt=isless], xs)

Sort `xs` by `lt` (which defaults to `isless`) and wrap in a SortedVector. For reverse
sorting, use `!lt`.

    SortedVector(SortedVectors.CheckSorted(), lt, sorted_contents)

Checks that the vector is sorted, throws an `ArgumentError` if it isn't. This is a
relatively cheap operation if the vector is supposed to be sorted but this should be
checked. Caller should `copy` the `sorted_contents` if they are mutable and may be modified.

    SortedVector(SortedVectors.AssumeSorted(), lt, sorted_contents)

Unchecked, unsafe constructor. Use only if you are certain that `sorted_contents` is sorted
according to `lt`, otherwise results are undefined. `copy` the `sorted_contents` if they are
mutable and may be modified.
"""
function SortedVector(lt, xs::AbstractVector)
    SortedVector(AssumeSorted(), lt, sort(xs; lt = lt))
end

SortedVector(xs::AbstractVector) = SortedVector(isless, xs)

Base.parent(sv::SortedVector) = sv.sorted_contents

####
#### array interface
####

@forward SortedVector.sorted_contents (Base.size, Base.getindex, Base.length, Base.axes)

Base.IndexStyle(::Type{<:SortedVector}) = Base.IndexLinear()

function Base.setindex!(sv::SortedVector, x, i::Integer)
    @unpack lt, sorted_contents = sv
    a, b = firstindex(sorted_contents), lastindex(sorted_contents)
    a < i ≤ b && @argcheck lt(sorted_contents[i-1], x)
    a ≤ i < b && @argcheck lt(x, sorted_contents[i+1])
    sorted_contents[i] = x
end

####
#### cut
####

Base.searchsortedfirst(sv::SortedVector, x) =
    searchsortedfirst(sv.sorted_contents, x; lt = sv.lt)

"""
$(SIGNATURES)

Return `i` such that `breaks[i] < x ≤ breaks[i + 1]`, where `<` is the sorting from the
second argument.

When `x ≤ breaks[1]`, `left` (0 by default) is used, and `right` (default: length) for `x >
breaks[end]`.
"""
function cut(x, breaks::SortedVector; left = 0, right = length(breaks))
    ix = searchsortedfirst(breaks, x) - 1
    ix == 0 ? left : (ix == length(breaks) ? right : ix)
end

end # module
