
"""
    xor_swap(a, b)

This is an old trick to exchange the values of variables a and b without using
an additional temporary variable.
"""
macro xor_swap(a, b)
    esc(:($a ⊻= $b; $b ⊻= $a; $a ⊻= $b)) 
end

"""
    swapbits{T<:Unsigned}(x::T, i::Integer, j::Integer)

Swap the i'th and j'th bits in an unsigned integer.
Note this uses zero based indexes for `i` and `j`.

E.g. to swap the LSB and MSB of a byte: 1001 1000 (0x98) -> 0001 1001 (0x19)

```@example
swapbits(0x98, 0, 7)
```
"""
@inline function swapbits(x::T, i::Integer, j::Integer) where {T <: Unsigned}
    ibit = (x >> i) & T(1)
    jbit = (x >> j) & T(1)
    ixj = ibit ⊻ jbit
    ixj = (ixj << i) | (ixj << j)
    return x ⊻ ixj
end

@inline function _swap_bits_chunks_kernel(x, mask, offset)
    msk = repeatpattern(typeof(x), mask)
    return ((x >> offset) & msk) | ((x & msk) << offset)
end

@inline swap_odd_even_bits(x::Unsigned)        = _swap_bits_chunks_kernel(x, 0x55, 1)
@inline swap_consecutive_bitpairs(x::Unsigned) = _swap_bits_chunks_kernel(x, 0x33, 2) 
@inline swap_nibbles(x::Unsigned)              = _swap_bits_chunks_kernel(x, 0x0F, 4) 
@inline swap_bytes(x::Unsigned)                = _swap_bits_chunks_kernel(x, 0x00FF, 8)
@inline swap_uint16s(x::Unsigned)              = _swap_bits_chunks_kernel(x, 0x0000FFFF, 16)
@inline swap_uint32s(x::Unsigned)              = _swap_bits_chunks_kernel(x, 0x00000000FFFFFFFF, 32)
@inline swap_uint64s(x::Unsigned)              = _swap_bits_chunks_kernel(x, 0x0000000000000000FFFFFFFFFFFFFFFF, 64)
