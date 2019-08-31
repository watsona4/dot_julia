# Counting bits

```@meta
CurrentModule = Twiddle
DocTestSetup  = quote
    using Twiddle
end
```

Twiddle provides functions that make it easy to count the number of times certain
bit patterns occur in a set of bits.

## Counting pairs of bits

```@doc
Twiddle.count_nonzero_bitpairs
Twiddle.count_00_bitpairs
Twiddle.count_11_bitpairs
Twiddle.count_01_bitpairs
Twiddle.count_10_bitpairs
```

## Counting nibbles (groups of 4 bits)

```@doc
Twiddle.count_nonzero_nibbles
Twiddle.count_0000_nibbles
Twiddle.count_1111_nibbles
```