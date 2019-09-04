XFloat16(x::Float16)  = reinterpret(XFloat16, Float32(x))
XFloat16(x::Float64)  = reinterpret(XFloat16, Float32(x))
XFloat16(x::BigFloat) = reinterpret(XFloat16, Float32(x))

XFloat32(x::Float16)  = reinterpret(XFloat32, Float64(x))
XFloat32(x::Float32)  = reinterpret(XFloat32, Float64(x))
XFloat32(x::BigFloat) = reinterpret(XFloat32, Float64(x))

Float16(x::XFloat16)  = Float16(reinterpret(Float32, x))
Float64(x::XFloat16)  = Float64(reinterpret(Float32, x))
BigFloat(x::XFloat16) = BigFloat(reinterpret(Float32, x))

Float16(x::XFloat32)  = Float16(reinterpret(Float64, x))
Float32(x::XFloat32)  = Float32(reinterpret(Float64, x))
BigFloat(x::XFloat32) = BigFloat(reinterpret(Float64, x))

for T in (:Int8, :Int16, :Int32, :Int64, :Int128, :BigInt,
          :UInt8, :UInt16, :UInt32, :UInt64, :UInt128)
  @eval begin
    XFloat16(x::$T) = reinterpret(XFloat16, Float32(x))
    XFloat32(x::$T) = reinterpret(XFloat32, Float64(x))
    $T(x::XFloat16) = $T(reinterpret(Float32,x))
    $T(x::XFloat32) = $T(reinterpret(Float64,x))
  end
end

XFloat16(x::Bool) = reinterpret(XFloat16, Float32(x))
XFloat32(x::Bool) = reinterpret(XFloat32, Float64(x))
Bool(x::XFloat16) = Bool(reinterpret(Float32, x))
Bool(x::XFloat32) = Bool(reinterpret(Float64, x))
