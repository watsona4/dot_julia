module LowLevelFloatFunctions

export bitwidth, signbit, 
       sign, precision, exponent, biased_exponent, significand,
       sign_bits, exponent_bits, significand_bits,
       exponent_max, exponent_min, exponent_field_max,
       exponent_bias, unbias_exponent, bias_exponent,
       sign_field, exponent_field, significand_field,
       unbiased_exponent_field, biased_exponent_field,
       sign_and_exponent_fields, exponent_and_significand_fields,
       floating

import Base: signed, unsigned
import Base.Math: precision, significand_bits, exponent_bits, exponent_bias

const SysFloat = Union{Float64, Float32, Float16}



biased_exponent(x::T) where T<:SysFloat = Int(biased_exponent_field(x))
unbias_exponent(x::T) where T<:SysFloat = Int(x - exponent_bias(T))

# extend coverage to Unsigneds for field processing functions

for F in (:precision, :significand_bits, :exponent_bits)
    for (T,U) in ((:Float64, :UInt64), (:Float32, :UInt32), (:Float16, :UInt16))
        @eval begin
            @inline $F(::Type{$U}) = $F($T)
        end
    end
end

@inline sign_bits(::Type{T}) where T<:SysFloat = 1
@inline sign_bits(::Type{T}) where T<:Union{UInt64, UInt32, UInt16} = 1

@inline bitwidth(::Type{T}) where T = sizeof(T) * 8

@inline exponent_max(::Type{Float16})  =     15
@inline exponent_max(::Type{Float32})  =    127
@inline exponent_max(::Type{Float64})  =   1023

@inline exponent_min(::Type{T}) where T<:SysFloat = 1 - exponent_max(T)

@inline exponent_bias(::Type{UInt16})  =     15%UInt16
@inline exponent_bias(::Type{UInt32})  =    127%UInt32
@inline exponent_bias(::Type{UInt64})  =   1023%UInt64
@inline exponent_bias(::Type{Float16}) =     15%Int16
@inline exponent_bias(::Type{Float32}) =    127%Int32
@inline exponent_bias(::Type{Float64}) =   1023%Int64

@inline exponent_field_max(::Type{T}) where T<:SysFloat = exponent_max(T) + one(convert(Unsigned, T))

# extend coverage to Unsigneds for field processing functions

for F in (:exponent_max, :exponent_min, :exponent_field_min)
    for (T,U) in ((:Float64, :UInt64), (:Float32, :UInt32), (:Float16, :UInt16))
        @eval begin
            @inline $F(::Type{$U}) = $F($T)
        end
    end
end

include("convert.jl")
include("def_fields.jl")
include("getset_fields.jl")

end # module LowLevelFloatFunctions
