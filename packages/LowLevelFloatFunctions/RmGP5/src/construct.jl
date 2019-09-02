#=
    float(Int1
=#
import Base:signed, unsigned

@inline floating(::Type{ UInt16}) = Float16
@inline floating(::Type{ UInt32}) = Float32
@inline floating(::Type{ UInt64}) = Float64
@inline floating(::Type{  Int16}) = Float16
@inline floating(::Type{  Int32}) = Float32
@inline floating(::Type{  Int64}) = Float64
@inline floating(::Type{Float16}) = Float16
@inline floating(::Type{Float32}) = Float32
@inline floating(::Type{Float64}) = Float64


@inline signed(::Type{ UInt16}) = Int16
@inline signed(::Type{ UInt32}) = Int32
@inline signed(::Type{ UInt64}) = Int64
@inline signed(::Type{UInt128}) = Int128
@inline signed(::Type{  Int16}) = Int16
@inline signed(::Type{  Int32}) = Int32
@inline signed(::Type{  Int64}) = Int64
@inline signed(::Type{ Int128}) = Int128
@inline signed(::Type{Float16}) = Int16
@inline signed(::Type{Float32}) = Int32
@inline signed(::Type{Float64}) = Int64


@inline unsigned(::Type{ UInt16}) = UInt16
@inline unsigned(::Type{ UInt32}) = UInt32
@inline unsigned(::Type{ UInt64}) = UInt64
@inline unsigned(::Type{UInt128}) = UInt128
@inline unsigned(::Type{  Int16}) = UInt16
@inline unsigned(::Type{  Int32}) = UInt32
@inline unsigned(::Type{  Int64}) = UInt64
@inline unsigned(::Type{ Int128}) = UInt128
@inline unsigned(::Type{Float16}) = UInt16
@inline unsigned(::Type{Float32}) = UInt32
@inline unsigned(::Type{Float64}) = UInt64


@inline floating(x::T) where T<:Union{Signed, Unsigned, Base.IEEEFloat} =
   reinterpret(floating(T), x)
@inline signed(x::T) where T<:Union{Signed, Unsigned, Base.IEEEFloat} =
   reinterpret(signed(T), x)
@inline unsigned(x::T) where T<:Union{Signed, Unsigned, Base.IEEEFloat} =
   reinterpret(unsigned(T), x)
