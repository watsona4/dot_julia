# Working with Nibbles

## What is a nibble?

A nibble (often nybble or nyble to match the vowels of byte) is a four-bit
aggregation. It is also sometimes called a half-byte or tetrade.

A nibble has sixteen possible values. A nibble can be represented by a single
hexadecimal digit, called a hex digit.

For example, if you wanted to represent the byte 00001111, you would use two hex
digits, one hex digit would represent the 0000 bits, and a second hex digit
would represent the 1111 bits. So the byte - the two nibbles - are represented
in hexadecimal notation as: 0x0F. The hex digit 0 = the 0000 nibble, and the hex
digit F = the 1111 nibble.

## Why would you want to manipulate nibbles?

### In Bioinformatics...

You may have some data encoded in a succinct format that
stores memory and will speed up computation, but that requires manipulating
bits of binary data.

In the BioJulia package ecosystem, DNA sequences can
be represented in a compressed format where a single nucleotide is represented
with a nibble.

Since many nibbles can fit in a single integer, bit parallel
manipulation of such binary data allows you to do operations on many nibbles
(nucleotides) at once, speeding up your computation significantly!

# Nibble methods

- [`Twiddle.nibble_capacity`](@ref)
- [`Twiddle.enumerate_nibbles`](@ref)
- [`Twiddle.count_nonzero_nibbles`](@ref)
- [`Twiddle.count_zero_nibbles`](@ref)
- [`Twiddle.count_one_nibbles`](@ref)
- [`Twiddle.nibble_mask`](@ref)
