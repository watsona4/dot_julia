BitFields conforming to the IEEE Floating Point Standard


Standards conformant binary floating point represenentations
have "three componants: a sign, an exponent, and a significand" [§2.1.26]

The _sign_ is encoded in the most significant bit of the value_store.
The bitfield for the floating-point sign (nonnegative or negative)
has a span of 1 bit and a shift of `bitsof(value_store) - 1`
(shifting 1 bit placed in the least significant bit of the value_store
by bitsof(value_store) bit positions would shift it out of the value_store).

The exponent is encoded in a bitfield that follows the sign's bitfield.
The exponent bitfield is adjacent to the sign bitfield, from below
(where `below` means that the sign bitfield occupies a more significant
position in the value_store than does the exponent bitfield; with
respect to positional significance, the exponent bitfield follows
the sign bitfield).  The span of the exponent bitfield is given
by fiat in the Standard (see table 3.2).

The shift of the exponent bitfield is less than the shift of the
sign bitfield, as that field occupies a more significant (the most
significant) position in the value_store.  How much less is the 
shift of the exponent bitfield, exactly as many as there are
bits in the exponent bitfield.  The shift of the exponent BitField
can be ascertained as
`bitsof(value_store) - 1 - span of exponent bitfield`.

The span of the significand bitfield is mandated, too.
The least significant bit of the significand BitField
occupies the least significant bit of the value_store.
Therefore, the shift of the significand bitfield is 0.


```julia

fieldspan(::Type{T}, fieldmask) where {T<:IEEEFloat} =
    bitsof(T) - leading_zeros(fieldmask(T)) - trailing_zeros(fieldmask(T))

fieldshift(::Type{T}, fieldmask) where {T<:IEEEFloat} = trailing_zeros(fieldmask(T))

# generating the bitfields for a Float64, and a Float32, the direct way

sign64 = BitField(UInt64, fieldspan(Float64, sign_mask), fieldshift(Float64, sign_mask), :sign)
exponent64 = BitField(UInt64, fieldspan(Float64, exponent_mask), fieldshift(Float64, exponent_mask), :exponent)
significand64  = BitField(UInt64, fieldspan(Float64, significand_mask), fieldshift(Float64, significand_mask), :significand)

float64 = BitFields(sign64, exponent64, significand64)

sign32 = BitField(UInt32, fieldspan(Float32, sign_mask), fieldshift(Float32, sign_mask), :sign)
exponent32 = BitField(UInt32, fieldspan(Float32, exponent_mask), fieldshift(Float32, exponent_mask), :exponent)
significand32  = BitField(UInt32, fieldspan(Float32, significand_mask), fieldshift(Float32, significand_mask), :significand)

float32 = BitFields(sign32, exponent32, significand32)
=#

#=
# generating the bitfields for a Float64 and a Float32, a more compact way

Base.unsigned(::Type{Float64}) = UInt64
Base.unsigned(::Type{Float32}) = UInt32
Base.unsigned(::Type{Float16}) = UInt16


BitField(::Type{T}, mask::Function, name::Symbol) where {T<:IEEEFloat} =
    BitField(unsigned(T), fieldspan(T, mask), fieldshift(T, mask), name)

sign64 = BitField(Float64, sign_mask, :sign)
exponent64 = BitField(Float64, exponent_mask, :exponent)
significand64 = BitField(Float64, significand_mask, :significand)

float64 = BitFields(sign64, exponent64, significand64)

sign32 = BitField(Float32, sign_mask, :sign)
exponent32 = BitField(Float32, exponent_mask, :exponent)
significand32 = BitField(Float32, significand_mask, :significand)

float32 = BitFields(sign32, exponent32, significand32)
=#
```
