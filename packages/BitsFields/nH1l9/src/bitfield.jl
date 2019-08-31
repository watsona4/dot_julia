"""
    BitCount

type used to hold bit counts and shift amounts
"""
const BitCount = Int16

"""
    BitField

The structured BitField.

fields:
    nbits
    shift
    maskof1s
    maskof0s
    name::Symbol
"""
struct BitField{U} <: AbstractBitField
    nbits::BitCount
    shift::BitCount
    maskof1s::U
    maskof0s::U
    name::Symbol
end

Base.eltype(::Type{BitField{U}}) where {U} = U
Base.eltype(x::BitField{U}) where {U} = U

name(x::BitField{U}) where {U<:UBits} = x.name
nbits(x::BitField{U}) where {U<:UBits} = x.nbits
shift(x::BitField{U}) where {U<:UBits} = x.shift
maskof1s(x::BitField{U}) where {U<:UBits} = x.maskof1s
maskof0s(x::BitField{U}) where {U<:UBits} = x.maskof0s

const BitField8 = BitField{UInt8}
const BitField16 = BitField{UInt16}
const BitField32 = BitField{UInt32}
const BitField64 = BitField{UInt64}
const BitField128 = BitField{UInt128}

BitField8(; name::Symbol, bitspan::Int, bitshift::Int) = BitField(UInt8, bitspan, bitshift, name)
BitField16(; name::Symbol, bitspan::Int, bitshift::Int) = BitField(UInt16, bitspan, bitshift, name)
BitField32(; name::Symbol, bitspan::Int, bitshift::Int) = BitField(UInt32, bitspan, bitshift, name)
BitField64(; name::Symbol, bitspan::Int, bitshift::Int) = BitField(UInt64, bitspan, bitshift, name)
BitField128(; name::Symbol, bitspan::Int, bitshift::Int) = BitField(UInt128, bitspan, bitshift, name)

function BitField(::Type{U}, bitspan::Int, bitshift::Int, name::Symbol) where {U<:UBits}
    span  = BitCount(bitspan)
    shift = BitCount(bitshift)
    validate(U, span, shift)

    maskof1s = onebits(U, span, shift)
    maskof0s = ~maskof1s
    return BitField{U}(span, shift, maskof1s, maskof0s, name)
end

BitField(::Type{U}, name::Symbol, bitspan::Int, bitshift::Int) where {U<:UBits} =
    BitField(U, bitspan, bitshift, name)

BitField(bitspan::Int, bitshift::Int, name::Symbol) = BitField(UInt64, bitspan, bitshift, name)

BitField(name::Symbol, bitspan::Int, bitshift::Int) = BitField(UInt64, bitspan, bitshift, name)


@inline function isolate(bitfield::BitField{U}, source::U) where {U<:UBits}
    return source & bitfield.maskof1s
end

@inline function filter(bitfield::BitField{U}, source::U) where {U<:UBits}
    return source & bitfield.maskof0s
end

@inline function Base.get(bitfield::BitField{U}, source::U) where {U<:UBits}
    return isolate(bitfield, source) >> bitfield.shift
end

@inline function Base.get(bitfield::BitField{U}, source::Base.RefValue{U}) where {U<:UBits}
    return isolate(bitfield, source[]) >> bitfield.shift
end

@inline function Base.get(bitfield::BitField{U}, source::ByRef{S,U}) where {S,U<:UBits}
    return isolate(bitfield, source.ref[]) >> bitfield.shift
end

@inline function put(bitfield::BitField{U}, value::U) where {U<:UBits}
    value << bitfield.shift
end


set(bitfield::BitField{U}, value::B, target::U) where {U<:UBits, B<:Union{UBits,IBits}} =
    set(bitfield, value%U, target)

set!(bitfield::BitField{U}, value::B, target::Base.RefValue{U})  where {U<:UBits, B<:Union{UBits,IBits}} =
    set!(bitfield, value%U, target)

set!(bitfield::BitField{U}, value::B, target::ByRef{S,U})  where {S, U<:UBits, B<:Union{UBits,IBits}} =
    set!(bitfield, value%U, target)


@inline function set(bitfield::BitField{U}, value::U, target::U)  where {U<:UBits}
    return filter(bitfield, target) | put(bitfield, value)
end

@inline function set!(bitfield::BitField{U}, value::U, target::Base.RefValue{U})  where {U<:UBits}
    target[] = set(bitfield, value, target[])
    return target
end

@inline function set!(bitfield::BitField{U}, value::U, target::ByRef{S, U})  where {S, U<:UBits}
    target.ref[] = set(bitfield, value, target.ref[])
    return target
end



function validate(::Type{U}, bitspan::Integer, bitshift::Integer) where {U<:UBits}
    if !(bitspan > 0 && bitspan + bitshift <= bitsof(U))
        if bitspan <= 0
            throw(ErrorException("bitspan ($bitspan) must be > 0"))
        else
            throw(ErrorException("bitspan + bitshift > totalbits: $bitspan + $bitshift > $(bitsizeof(U))"))
        end
    end
    return nothing
end


onebits(::Type{T}, bitspan::I, bitshift::I) where {T<:UBits, I<:Integer} =
    ~(~zero(T) << bitspan) << bitshift
