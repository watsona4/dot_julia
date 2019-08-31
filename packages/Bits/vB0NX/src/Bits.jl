# * Bits

module Bits

export bit, bits, bitsize, low0, low1, mask, masked, scan0, scan1, tstbit, weight
using Base: BitInteger, BitIntegerType


# * constants

const Index = Int # do not change

const Word = UInt # default integer type

"""
`INF::Int` indicates the position of the bit at "infinity", for types
which can carry an arbitrary number of bits, like BigInt.
`INF` is also used to indicate an arbitrary large number of bits.
Currently, `Bits.INF == typemax(Int)`.
"""
const INF = typemax(Index)

"""
`NOTFOUND::Int` indicates that no position matches the request, similar
to `nothing` with `findnext`. Currently, `Bits.NOTFOUND == 0`.
"""
const NOTFOUND = 0

const BitFloats = Union{Float16,Float32,Float64}

const MPFR_EXP_BITSIZE = sizeof(Clong) * 8

# * bitsize

"""
    bitsize(T::Type) -> Int
    bitsize(::T)     -> Int

Return the number of bits that can be held by type `T`.
Only the second method may be defined when the number of bits
is a dymanic value, like for `BitFloat`.

# Examples
```jldoctest
julia> bitsize(Int32)  == 32        &&
       bitsize(true)   == 1         &&
       bitsize(big(0)) == Bits.INF  &&
       bitsize(1.2)    == 64
true

julia> x = big(1.2); bitsize(x) == 256 + sizeof(x.exp)*8 + 1
true
```
"""
bitsize(::Type{BigInt}) = INF
bitsize(::Type{Bool}) = 1
bitsize(T::Type) = bitsize(Val(isbitstype(T)), T)

bitsize(isbits::Val{true}, T::Type) = sizeof(T) * 8
bitsize(isbits::Val{false}, T::Type) = throw(MethodError(bitsize, (T,)))

bitsize(x) = bitsize(typeof(x))

bitsize(x::BigFloat) =  1 + MPFR_EXP_BITSIZE + precision(x)

lastactualpos(x) = bitsize(x)
lastactualpos(x::BigInt) = abs(x.size) * sizeof(Base.GMP.Limb) * 8

asint(x::Integer) = x
asint(x::AbstractFloat) = reinterpret(Signed, x)


# * bit functions: weight, bit, tstbit, mask, low0, low1, scan0, scan1

# ** weight

"""
    weight(x::Real) -> Int

Hamming weight of `x` considered as a binary vector.
Similarly to `count_ones(x)`, counts the number of `1` in the bit representation of `x`,
but not necessarily at the "bare-metal" level; for example `count_ones(big(-1))` errors out,
while `weight(big(-1)) == Bits.INF`, i.e. a `BigInt` is considered to be an arbitrary large
field of bits with twos complement arithmetic.

# Examples
```jldoctest
julia> weight(123)
6

julia> count(bits(123))
6
```
"""
weight(x::Real) = count_ones(x)
weight(x::BigInt) = x < 0 ? INF : count_ones(x)


# ** bit

"""
    bit(x::Integer, i::Integer)       -> typeof(x)
    bit(x::AbstractFloat, i::Integer) -> Integer

Return the bit of `x` at position `i`, with value `0` or `1`.
If `x::Integer`, the returned bit is of the same type.
If `x::AbstractFloat` is a bits type, the returned bit is a signed integer with the same [`bitsize`](@ref) as `x`.
See also [`tstbit`](@ref).

# Examples
```jldoctest
julia> bit(0b101, 1)
0x01

julia> bit(0b101, 2)
0x00

julia> bit(-1.0, 64)
1
```
"""
bit(x::Integer, i::Integer) = (x >>> UInt(i-1)) & one(x)
bit(x::AbstractFloat, i::Integer) = bit(asint(x), i)
bit(x::Union{BigInt,BigFloat}, i::Integer) = tstbit(x, i) ? big(1) : big(0)


# ** tstbit

"""
    tstbit(x::Real, i::Integer) -> Bool

Similar to [`bit`](@ref) but returns the bit at position `i` as a `Bool`.

# Examples
```jldoctest
julia> tstbit(0b101, 3)
true
```
"""
tstbit(x, i::Integer) = bit(x, i) % Bool
tstbit(x::BigInt, i::Integer) = Base.GMP.MPZ.tstbit(x, i-1)

# from Random module
using Base.GMP: Limb
const bits_in_Limb = bitsize(Limb)
const Limb_high_bit = one(Limb) << (bits_in_Limb-1)

function tstbit(x::BigFloat, i::Integer)
    prec = precision(x)
    if i > prec
        i -= prec
        if i > MPFR_EXP_BITSIZE
            i == MPFR_EXP_BITSIZE + 1 ? (x.sign == -1) : false
        else
            tstbit(x.exp, i)
        end
    else
        nlimbs = (prec-1) ÷ bits_in_Limb + 1
        tstbit(x.d, i + nlimbs * bits_in_Limb - prec)
    end
end

tstbit(p::Ptr{T}, i::Integer) where {T} =
    tstbit(unsafe_load(p, 1 + (i-1) ÷ bitsize(T)),
           mod1(i, bitsize(T)))


# ** mask

"""
    mask(T::Type{<:Integer}:=UInt, i::Integer=bitsize(T)) -> T

Return an integer of type `T` whose `i` right-most bits are `1`, and the
others are `0` (i.e. of the form `0b0...01...1` with exactly `i` `1`s.
When `i` is not specified, all possible bits are set to `1`.
When `i < 0`, the result is not specified.
`T` defaults to `UInt`.

# Examples
```jldoctest
julia> mask(3)
0x0000000000000007

julia> mask(UInt8)
0xff

julia> bits(mask(Int32, 24))
<00000000 11111111 11111111 11111111>
```
"""
mask(::Type{T}, i::Integer) where {T} = one(T) << i - one(T)

# alternate implementation:
mask_2(T::BitIntegerType, i::Integer) = let s = bitsize(T)-i
    mask(T) << s >>> s
end

mask(i::Integer) = mask(Word, i)

mask(::Type{T}=Word) where {T} = ~zero(T)

# TODO: optimize
mask(::Type{BigInt}, i::Integer) = one(BigInt) << i - 1

"""
    mask(T::Type{<:Integer} := UInt, j::Integer, i::Integer) -> T

Return an integer of type `T` whose `j` right-most bits are `0`, the
following `i-j` bits are `1`, and the remaining bits are `0`
(i.e. of the form `0b0...01...10...0` with exactly `i-j` `1`s preceded by
`j` `0`s).
When `j < 0`, the result is not specified.
When `i < 0`, the result is equal to `~mask(T, j)`, i.e. of the form
`1...10...0` with exactly `j` zeros.
NOTE: unstable API, could be changed to mask(j, i-j) instead.

# Examples
```jldoctest
julia> bits(mask(UInt8, 2, 5))
<00011100>

julia> bits(mask(BigInt, 3, -1))
<...1 11111111 11111111 11111111 11111111 11111111 11111111 11111111 11111000>
```
"""
mask(::Type{T}, j::Integer, i::Integer) where {T} = mask(T, i-j) << j

# alternate implementation
mask_2(::Type{T}, j::Integer, i::Integer) where {T} = mask(T, i) & ~mask(T, j)

mask(j::Integer, i::Integer) = mask(Word, j, i)


# ** masked

"""
    masked(x, [j::Integer], i::Integer) -> typeof(x)

Return the result of applying the mask `mask(x, [j], i)` to `x`, i.e.
`x & mask(x, [j], i)`.
If `x` is a float, apply the mask to the underlying bits.

# Examples
```jldoctest
julia> masked(0b11110011, 1, 5) === 0b00010010
true

julia> x = rand(); masked(-x, 0, 63) === x
true
```
"""
masked(x, i::Integer) = x & mask(typeof(x), i)
masked(x, j::Integer, i::Integer) = x & mask(typeof(x), j, i)
masked(x::AbstractFloat, i::Integer) = reinterpret(typeof(x), masked(asint(x), i))
masked(x::AbstractFloat, j::Integer, i::Integer) = reinterpret(typeof(x), masked(asint(x), j, i))


# ** low0 & low1, scan0 & scan1

"""
    low0(x, n::Integer=1)
    low1(x, n::Integer=1)

Return the position of the `n`th `0` (for `low0`) or `1` (for `low1`) in `x.

# Examples
```jldoctest
julia> low0(0b10101, 2)
4

julia> low1(0b10101, 4) == Bits.NOTFOUND
true
```
"""
low0, low1

low0(x) = scan0(x)
low1(x) = scan1(x)

low0(x, n::Integer) = low1(~asint(x), n)

function low1(x, n::Integer)
    i = 0
    while n > 0
        i = scan1(x, i+1)
        i === 0 && break
        n -= 1
    end
    i
end

"""
    scan0(x, n::Integer=1)
    scan1(x, n::Integer=1)

Return the position of the first `0` (for `scan0`) or `1` (for `scan1`) after or including `n` in `x`.

# Examples
```jldoctest
julia> scan0(0b10101, 1)
2

julia> scan1(0b10101, 6) == Bits.NOTFOUND
true
```
"""
scan0, scan1

scan0(x, i::Integer=1) = scan1(~asint(x), i)

function scan1(x, i::Integer=1)
    i < 1 && return NOTFOUND
    y = asint(x) >>> (i % UInt - 1)
    iszero(y) ? NOTFOUND : i + trailing_zeros(y)
end

@assert NOTFOUND === 0
# unfortunately, in Base.GMP.MPZ the wrapper converts to Int and fails for big(-1) or big(0)
scan0(x::BigInt, i::Integer=1) = 1 + ccall((:__gmpz_scan0, :libgmp), Culong, (Ref{BigInt}, Culong), x, i % Culong - 1) % Int
scan1(x::BigInt, i::Integer=1) = 1 + ccall((:__gmpz_scan1, :libgmp), Culong, (Ref{BigInt}, Culong), x, i % Culong - 1) % Int


# * bits & BitVector1

"""
    bits(x::Real)

Create an immutable view on the bits of `x` as a vector of `Bool`, similar to a `BitVector`.
If `x` is a `BigInt`, the vector has length [`Bits.INF`](@ref).
Currently, no bounds check is performed when indexing into the vector.

# Examples
```jldoctest
julia> v = bits(Int16(2^8+2^4+2+1))
<00000001 00010011>

julia> permutedims([v[i] for i in 8:-1:1])
1×8 Array{Bool,2}:
 false  false  false  true  false  false  true  true

julia> bits(true)
<1>

julia> bits(big(2)^63)
<...0 10000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000>

julia> bits(Float32(-7))
<1|10000001|1100000 00000000 00000000>

julia> ans[1:23] # creates a vector of bits with a specific length
<1100000 00000000 00000000>
```
"""
bits(x::Real) = BitVector1(x)


# ** BitVector1

# similar to a BitVector, but with only 1 word to store bits (instead of 1 array thereof)
abstract type AbstractBitVector1 <: AbstractVector{Bool} end

struct BitVector1{T<:Real} <: AbstractBitVector1
    x::T
end

struct BitVector1Mask{T<:Real} <: AbstractBitVector1
    x::T
    len::Int
end

Base.size(v::BitVector1) = (bitsize(v.x),)
Base.size(v::BitVector1Mask) = (v.len,)
Base.getindex(v::AbstractBitVector1, i::Integer) = tstbit(v.x, i)

function Base.getindex(v::AbstractBitVector1, a::AbstractVector{<:Integer})
    xx, _ = foldl(a, init=(zero(asint(v.x)), 0)) do xs, i
        x, s = xs
        (x | bit(v.x, i) << s, s+1)
    end
    BitVector1Mask(xx, length(a))
end

function Base.getindex(v::AbstractBitVector1, a::AbstractUnitRange{<:Integer})
    j, i = extrema(a)
    x = masked(asint(v.x), j-1, i) >> (j-1)
    BitVector1Mask(x, length(a))
end


# ** show

sig_exp_bits(x) = Base.Math.significand_bits(typeof(x)), Base.Math.exponent_bits(typeof(x))
sig_exp_bits(x::BigFloat) = precision(x), MPFR_EXP_BITSIZE

showsep(io, x, i) = (i % 8 == 0) && print(io, ' ')

function showsep(io, x::AbstractFloat, i)
    sigbits, expbits = sig_exp_bits(x)
    if i == sigbits || i == sigbits + expbits
        print(io, '|')
    elseif i < sigbits && i % 8 == 0 || i > sigbits && (i-sigbits) % 8 == 0
        print(io, ' ')
    end
end

function Base.show(io::IO, v::AbstractBitVector1)
    if v.x isa BigInt && v isa BitVector1
        print(io, "<...", v.x < 0 ? "1 " : "0 ")
    else
        print(io, "<")
    end
    l = v isa BitVector1 ? lastactualpos(v.x) : v.len
    for i = l:-1:1
        i != l && showsep(io, v.x, i)
        show(io, v[i] % Int)
    end
    print(io, ">")
end

Base.show(io::IO, ::MIME"text/plain", v::AbstractBitVector1) = show(io, v)


end # module
