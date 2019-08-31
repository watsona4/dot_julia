#=
Nibble operations
=================

Copyright (c) 2017 Ben J. Ward & Luis Yanes

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
=#

"""
    nibble_capacity{T<:Unsigned}(::Type{T})

Returns the number of nibbles that an unsigned integer of type `T`
holds. This is essentially twice the size of the type (in bytes).
"""
@inline function nibble_capacity(::Type{T}) where {T<:Unsigned}
    return sizeof(T) * 2
end

@inline function bitpair_capacity(::Type{T}) where {T<:Unsigned}
    return sizeof(T) * 4
end

"""
    enumerate_nibbles{T<:Unsigned}(x::T)

Count the number of set bits in each nibble (aligned 4 bit segments) of an
unsigned integer `x`.

E.g. An input of:

0100 0010 0001 0110 1100 1110 1101 1111

Would result in:

0001 0001 0001 0010 0010 0011 0011 0100

This is used to identify different occurances of certain bit patterns.
"""
@inline function enumerate_nibbles(x::T) where {T<:Unsigned}
    x = x - ((x >>> 1) & repeatpattern(T, 0x55))
    return (x & repeatpattern(T, 0x33)) + ((x >>> 2) & repeatpattern(T, 0x33))
end

