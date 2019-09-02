## String utilities for vectors.

"""
Non-standard string literal `sz`.

Convert a space-separated string to an occupation vector.
"""
macro sz_str(x)
    Int[parse(Int, n) for n in split(x)]
end

"""
    to_str(v::Vector{Int})

Convert an occupation vector `v` to a space-separated string.
"""
to_str(v::AbstractVector{Int}) = join(v, " ")
