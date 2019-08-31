#=
Masking operations
==================

Copyright (c) 2017 Ben J. Ward & Luis Yanes

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
=#

"""
    nibble_mask{T<:Unsigned}(value::T, x::T)

Create a mask for the nibbles (aligned 4 bit segments) in an unsigned integer
`x` that filter nibbles matching the corresponding nibble in `value`.
"""
@inline function nibble_mask(value::T, x::T) where {T<:Unsigned}
    # XOR with the desired values. So matching nibbles will be 0000.
    x = x ⊻ value
    # Horizontally OR the nibbles.
    x |= (x >>> 1)
    x |= (x >>> 2)
    # AND removes junk, we then widen x by multiplication and return
    # the inverse.
    x &= repeatpattern(T, 0x11)
    x *= 0x0F
    return ~x
end

"""
    mask{T<:Unsigned}(::Type{T}, n::Integer)

Creates a bit mask for given number of bits `n`.

The mask starts from the least significant bit, and end at bit `n`.

e.g:

```jldoctest
julia> Twiddle.mask(UInt64, 8)
0x00000000000000ff
```
"""
@inline mask(::Type{T}, n::Integer) where {T<:Unsigned} = (T(1) << n) - 0x1
@inline mask(n::Integer) = mask(UInt64, n)