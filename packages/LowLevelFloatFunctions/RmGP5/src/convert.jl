# convert used as a generalized reinterpret

@inline Base.convert(::Type{Unsigned}, ::Type{Float16}) = UInt16
@inline Base.convert(::Type{Unsigned}, ::Type{Float32}) = UInt32
@inline Base.convert(::Type{Unsigned}, ::Type{Float64}) = UInt64

@inline Base.convert(::Type{SysFloat}, ::Type{UInt16}) = Float16
@inline Base.convert(::Type{SysFloat}, ::Type{UInt32}) = Float32
@inline Base.convert(::Type{SysFloat}, ::Type{UInt64}) = Float64

@inline Base.convert(::Type{Unsigned}, x::Float16) = reinterpret(Unsigned, x)
@inline Base.convert(::Type{Unsigned}, x::Float32) = reinterpret(Unsigned, x)
@inline Base.convert(::Type{Unsigned}, x::Float64) = reinterpret(Unsigned, x)

@inline Base.convert(::Type{SysFloat}, x::UInt16) = reinterpret(Float16, x)
@inline Base.convert(::Type{SysFloat}, x::UInt32) = reinterpret(Float32, x)
@inline Base.convert(::Type{SysFloat}, x::UInt64) = reinterpret(Float64, x)
