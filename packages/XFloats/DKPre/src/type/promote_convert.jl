Base.promote_rule(::Type{XFloat16}, ::Type{XFloat32}) = XFloat32
Base.promote_rule(::Type{XFloat32}, ::Type{XFloat16}) = XFloat32

Base.promote_rule(::Type{XFloat16}, ::Type{Float16} ) = XFloat16
Base.promote_rule(::Type{XFloat16}, ::Type{Float32} ) = Float32
Base.promote_rule(::Type{XFloat16}, ::Type{Float64} ) = Float64
Base.promote_rule(::Type{XFloat16}, ::Type{BigFloat}) = BigFloat
Base.promote_rule(::Type{Float16}, ::Type{XFloat16} ) = XFloat16
Base.promote_rule(::Type{Float32}, ::Type{XFloat16} ) = Float32
Base.promote_rule(::Type{Float64}, ::Type{XFloat16} ) = Float64
Base.promote_rule(::Type{BigFloat}, ::Type{XFloat16}) = BigFloat

Base.promote_rule(::Type{XFloat32}, ::Type{Float16} ) = XFloat32
Base.promote_rule(::Type{XFloat32}, ::Type{Float32} ) = XFloat32
Base.promote_rule(::Type{XFloat32}, ::Type{Float64} ) = Float64
Base.promote_rule(::Type{XFloat32}, ::Type{BigFloat}) = BigFloat
Base.promote_rule(::Type{Float16}, ::Type{XFloat32} ) = XFloat32
Base.promote_rule(::Type{Float32}, ::Type{XFloat32} ) = XFloat64
Base.promote_rule(::Type{Float64}, ::Type{XFloat32} ) = Float64
Base.promote_rule(::Type{BigFloat}, ::Type{XFloat32}) = BigFloat

Base.convert(::Type{XFloat16}, x::XFloat32) = reinterpret(XFloat16, Float32(reinterpret(Float64, x)))
Base.convert(::Type{XFloat32}, x::XFloat16) = reinterpret(XFloat32, Float64(reinterpret(Float32, x)))

Base.convert(::Type{XFloat16}, x::Float16)  = reinterpret(XFloat16, Float32(x))
Base.convert(::Type{XFloat16}, x::Float32)  = reinterpret(XFloat16, x)
Base.convert(::Type{XFloat16}, x::Float64)  = reinterpret(XFloat16, Float32(x))
Base.convert(::Type{XFloat16}, x::BigFloat) = reinterpret(XFloat16, Float32(x))

Base.convert(::Type{XFloat32}, x::Float16)  = reinterpret(XFloat32, Float64(x))
Base.convert(::Type{XFloat32}, x::Float32)  = reinterpret(XFloat32, Float64(x))
Base.convert(::Type{XFloat32}, x::Float64)  = reinterpret(XFloat32, x)
Base.convert(::Type{XFloat32}, x::BigFloat) = reinterpret(XFloat32, Float64(x))

Base.convert(::Type{Float16},  x::XFloat16) = Float16(reinterpret(Float32, x))
Base.convert(::Type{Float32},  x::XFloat16) = reinterpret(Float32, x)
Base.convert(::Type{Float64},  x::XFloat16) = Float64(reinterpret(Float32, x))
Base.convert(::Type{BigFloat}, x::XFloat16) = BigFloat(reinterpret(Float32, x))

Base.convert(::Type{Float16},  x::XFloat32) = Float16(reinterpret(Float64, x))
Base.convert(::Type{Float32},  x::XFloat32) = Float32(reinterpret(Float64, x))
Base.convert(::Type{Float64},  x::XFloat32) = reinterpret(Float64, x)
Base.convert(::Type{BigFloat}, x::XFloat32) = BigFloat(reinterpret(Float64, x))

for T in (:Int8, :Int16, :Int32, :Int64, :Int128, :BigInt,
          :UInt8, :UInt16, :UInt32, :UInt64, :UInt128)
  @eval begin
    Base.promote_rule(::Type{XFloat16}, ::Type{$T}) = XFloat16
    Base.promote_rule(::Type{XFloat32}, ::Type{$T}) = XFloat32
    Base.promote_rule(::Type{$T}, ::Type{XFloat16}) = XFloat16
    Base.promote_rule(::Type{$T}, ::Type{XFloat32}) = XFloat32
                    
    Base.convert(::Type{XFloat16}, x::$T) = XFloat16(Float32(x))
    Base.convert(::Type{XFloat32}, x::$T) = XFloat32(Float64(x))

    Base.convert(::Type{$T}, x::XFloat16) = $T(reinterpret(Float32,x))
    Base.convert(::Type{$T}, x::XFloat32) = $T(reinterpret(Float64,x))
  end
end
