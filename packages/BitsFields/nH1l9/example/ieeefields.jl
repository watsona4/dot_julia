using Base: IEEEFloat, unsigned, sign_mask, exponent_mask, significand_mask

using BitsFields
using BitsFields: bitsof, UBits


"""
    fieldspan

How many bits does this field span?

The tally of 1-bits in the field's mask gives its span.
All bits of a bitfield are adjacent to at least one other
bit within the bitfield. Interior bits, if any (if the
bitfield has a span of three or more), are adjacent to
two bits within bitfield.

To tally the 1-bits, we subtract any leading 0-bits
and subtract any trailing 0-bits from the
number of bits provided and given by the value_store.
(This way, no reliance on tabulated values is needed.
 We stay within the information availablilty of Julia.)
""" 
fieldspan(::Type{T}, fieldmask) where {T<:IEEEFloat} =
    bitsof(T) - leading_zeros(fieldmask(T)) - trailing_zeros(fieldmask(T))

"""
    fieldshift

By how many bits is this field shifted?
   - how far is the least significant bit of the field
     from the least significant bit of all the fields

To determine the number of bits over which a bitfield
is shifted (from low-order bits to high-order bits),
we count the empty bit positions that trail the bitfield.
"""
fieldshift(::Type{T}, fieldmask) where {T<:IEEEFloat} =
   trailing_zeros(fieldmask(T))


###################################################################

for N in (64, 32, 16)
  for (Field, Mask) in ( (:sign, :sign_mask), 
                         (:exponent, :exponent_mask), 
                         (:significand, :significand_mask) )
    @eval begin
      float_type = $(Symbol(:Float,N))
      uint_type  = $(Symbol(:UInt,N))
      $(Symbol(Field,N)) = BitField(uint_type,
                                    fieldspan(float_type, $Mask), 
                                    fieldshift(float_type, $Mask), 
                                    Symbol($Field))
    end
  end
end


float64 = NamedTuple(BitFields(sign64, exponent64, significand64))
float32 = NamedTuple(BitFields(sign32, exponent32, significand32))
float16 = NamedTuple(BitFields(sign16, exponent16, significand16))


z16 = ByRef(Float16, UInt16)

set!(float16.sign, 1, z16)
set!(float16.exponent, 15, z16)
set!(float16.significand, 0x0080, z16)

refvalue(z16) == Float16(-1.125)

nt = NamedTuple(float16, z16)
nt === (sign = 0x0001, exponent = 0x000f, significand = 0x0080)


# #################################
# Using the bitfields defined above
# #################################

Base.:(+)(a::ByRef{S,T}, b::S) where {S<:IEEEFloat, T<:UBits} = ByRef(refvalue(a) + b)
Base.:(+)(a::S, b::ByRef{S,T}) where {S<:IEEEFloat, T<:UBits} = ByRef(a + refvalue(b))
Base.:(+)(a::ByRef{S,T}, b::ByRef{S,T}) where {S<:IEEEFloat, T<:UBits} = ByRef(refvalue(a) + refvalue(b))

Base.:(*)(a::ByRef{S,T}, b::S) where {S<:IEEEFloat, T<:UBits} = ByRef(refvalue(a) * b)
Base.:(*)(a::S, b::ByRef{S,T}) where {S<:IEEEFloat, T<:UBits} = ByRef(a * refvalue(b))
Base.:(*)(a::ByRef{S,T}, b::ByRef{S,T}) where {S<:IEEEFloat, T<:UBits} = ByRef(refvalue(a) * refvalue(b))

a = ByRef(12.25)
b = ByRef(0.25)
c = -0.5

result = (a + b + c) * abs(c)
