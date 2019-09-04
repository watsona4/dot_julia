## ================================================================================ ##

const UnaryOps = (
    :precision, :exponent_mask, :signficand_mask, :exponent, :significand, :signbit,
    :iszero, :isone, :isfinite, :isinf, :isnan, :issubnormal, :isinteger)

const BinaryOps = (:(<), :(<=), :(>=), :(>), :(!=), :(==), :isless, :isequal, :cmp)

const UnaryOps_oftype = (
    :zero, :one, :ceil, :floor, :trunc, :round,
    :(+), :(-), :sign, :abs, :inv, :sqrt, :cbrt, 
    :log, :log1p, :log2, :log10, :exp, :expm1, :exp2, :exp10,
    :sin, :cos, :tan, :csc, :sec, :cot, :sinpi, :cospi,
    :sincos,
    :asin, :acos, :atan, :acsc, :asec, :acot,
    :sinh, :cosh, :tanh, :csch, :sech, :coth,
    :asinh, :acosh, :atanh, :acsch, :asech, :acoth)

const BinaryOps_oftype = (
    :(+), :(-), :(*), :(/), :(\), :hypot, :flipsign, :copysign,
    :mod, :mod1, :fld, :fld1, :div, :rem, :cld)


const TrinaryOps_oftype = (
    :clamp, :muladd, :fma)

const UnaryVectorOps_oftype = (
    :norm, :sum, :prod, :normalize
)

const UnaryMatrixOps_oftype = (
    :tr,
    :sqrt, :cbrt,
    :log, :log1p, :log2, :log10, :exp, :expm1, :exp2, :exp10,
    :sin, :cos, :tan, :csc, :sec, :cot, :sinpi, :cospi,
    :sincos,
    :asin, :acos, :atan, :acsc, :asec, :acot,
    :sinh, :cosh, :tanh, :csch, :sech, :coth,
    :asinh, :acosh, :atanh, :acsch, :asech, :acoth
)

const MatrixOperations = (
    :lu, :qr, :factorize,
)

#  ================================================================================  #

for (XT, FT) in ((:XFloat16, :Float32), (:XFloat32, :Float64))
  for Op in UnaryOps
    @eval $Op(x::$XT) = $Op(reinterpret($FT, x))
  end
  for Op in BinaryOps
    @eval $Op(x::$XT, y::$XT) = $Op(reinterpret($FT, x), reinterpret($FT, y))
  end
  for Op in UnaryOps_oftype
    @eval $Op(x::$XT) = reinterpret($XT, $Op(reinterpret($FT, x)))
  end
  for Op in BinaryOps_oftype
    @eval $Op(x::$XT, y::$XT) = reinterpret($XT, $Op(reinterpret($FT, x), reinterpret($FT, y)))
  end
  for Op in TrinaryOps_oftype
    @eval $Op(x::$XT, y::$XT, z::$XT) = reinterpret($XT, $Op(reinterpret($FT, x), reinterpret($FT, y), reinterpret($FT, z)))
  end

  for Op in UnaryVectorOps_oftype
    @eval $Op(x::Vector{$XT}) = reinterpret($XT, $Op(reinterpret($FT, x)))
  end
  
  for Op in UnaryMatrixOps_oftype
    @eval $Op(x::Matrix{$XT}) = reinterpret($XT, $Op(reinterpret($FT, x)))
  end
    
  
  (+)(x::Matrix{XFloat16}, y::Matrix{XFloat16}) =
      reinterpret(XFloat16, :(*)(reinterpret(Float32,x), reinterpret(Float32,y)))
  (+)(x::Matrix{XFloat32}, y::Matrix{XFloat32}) =
      reinterpret(XFloat32, :(*)(reinterpret(Float64,x), reinterpret(Float64,y)))
  (-)(x::Matrix{XFloat16}, y::Matrix{XFloat16}) =
      reinterpret(XFloat16, :(*)(reinterpret(Float32,x), reinterpret(Float32,y)))
  (-)(x::Matrix{XFloat32}, y::Matrix{XFloat32}) =
      reinterpret(XFloat32, :(*)(reinterpret(Float64,x), reinterpret(Float64,y)))
end

