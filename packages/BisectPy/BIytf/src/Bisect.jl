"""
# module Bisect



# Examples

```jldoctest
julia>
```
"""
module Bisect

export bisect_left, bisect_right

"""
    bisect_left(a, x, lo=1, hi=length(a))

Return the index where to insert item `x` in array `a`, assuming `a` is in an
non-decreasing order.

The return value `i` is such that all `e` in `a[:(i - 1)]` have `e < x`, and all `e` in
`a[i:]` have `e >= x`.  So if `x` already appears in the array, `insert!(a, i, x)` will
insert just before the leftmost `x` already there.

# Arguments
Optional args `lo` (default `1`) and `hi` (default `length(a)`) bound the
slice of `a` to be searched.

# Examples

```jldoctest
julia> bisect_left([1, 2, 3, 4, 5], 3.5)
4

julia> bisect_left([1, 2, 3, 4, 5], 2)
2

julia> bisect_left([1, 2, 3, 3, 3, 5], 3)
3
```
"""
function bisect_left(a, x, lo=1, hi=nothing)
    lo < 1 && throw(BoundsError(a, lo))
    hi == nothing && (hi = length(a))

    while lo < hi
        mid = (lo + hi) ÷ 2
        a[mid] < x ? lo = mid + 1 : hi = mid
    end
    lo
end

"""
    bisect_right(a, x, lo=1, hi=length(a))

Return the index where to insert item `x` in array `a`, assuming `a` is in an
non-decreasing order.

The return value `i` is such that all `e` in `a[:(i - 1)]` have `e <= x`, and all `e` in
`a[i:]` have `e > x`.  So if `x` already appears in the array, `insert!(a, i, x)` will
insert just after the rightmost `x` already there.

# Arguments
Optional args `lo` (default `1`) and `hi` (default `length(a)`) bound the
slice of `a` to be searched.

# Examples

```jldoctest
julia> bisect_right([1, 2, 3, 4, 5], 3.5)
4

julia> bisect_right([1, 2, 3, 4, 5], 2)
3

julia> bisect_right([1, 2, 3, 3, 3, 5], 3)
6
```
"""
function bisect_right(a, x, lo=1, hi=nothing)
    lo < 1 && throw(BoundsError(a, lo))
    hi == nothing && (hi = length(a))

    while lo < hi
        mid = (lo + hi) ÷ 2
        x < a[mid] ? hi = mid : lo = mid + 1
    end
    lo
end

end