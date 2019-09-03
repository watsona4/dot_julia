-(x::Single32) = Core.Intrinsics.neg_float(x)

+(x::Single32, y::Single32) = Core.Intrinsics.add_float(x, y)
-(x::Single32, y::Single32) = Core.Intrinsics.sub_float(x, y)
*(x::Single32, y::Single32) = Core.Intrinsics.mul_float(x, y)
/(x::Single32, y::Single32) = Core.Intrinsics.div_float(x, y)

muladd(x::Single32, y::Single32, z::Single32) = muladd_float(x, y, z)

+(x::Single32, y::Float64) = Core.Intrinsics.add_float(x, Single32(y))
-(x::Single32, y::Float64) = Core.Intrinsics.sub_float(x, Single32(y))
*(x::Single32, y::Float64) = Core.Intrinsics.mul_float(x, Single32(y))
/(x::Single32, y::Float64) = Core.Intrinsics.div_float(x, Single32(y))

+(x::Single32, y::Float32) = Core.Intrinsics.add_float(x, Single32(y))
-(x::Single32, y::Float32) = Core.Intrinsics.sub_float(x, Single32(y))
*(x::Single32, y::Float32) = Core.Intrinsics.mul_float(x, Single32(y))
/(x::Single32, y::Float32) = Core.Intrinsics.div_float(x, Single32(y))

+(x::Float64, y::Single32) = Core.Intrinsics.add_float(Single32(x), y)
-(x::Float64, y::Single32) = Core.Intrinsics.sub_float(Single32(x), y)
*(x::Float64, y::Single32) = Core.Intrinsics.mul_float(Single32(x), y)
/(x::Float64, y::Single32) = Core.Intrinsics.div_float(Single32(x), y)

+(x::Float32, y::Single32) = Core.Intrinsics.add_float(Single32(x), y)
-(x::Float32, y::Single32) = Core.Intrinsics.sub_float(Single32(x), y)
*(x::Float32, y::Single32) = Core.Intrinsics.mul_float(Single32(x), y)
/(x::Float32, y::Single32) = Core.Intrinsics.div_float(Single32(x), y)

muladd(x::Single32, y::Single32, z::Float64) = muladd_float(x, y, Single32(z))
muladd(x::Single32, y::Float64, z::Single32) = muladd_float(x, Single32(y), z)
muladd(x::Float64, y::Single32, z::Single32) = muladd_float(Single32(x), y, z)

muladd(x::Single32, y::Float64, z::Float64) = muladd_float(x, Single32(y), Single32(z))
muladd(x::Float64, y::Single32, z::Float64) = muladd_float(Single32(x), y, Single32(z))
muladd(x::Float64, y::Float64, z::Single32) = muladd_float(Single32(x), Single32(y), z)

muladd(x::Single32, y::Single32, z::Float32) = muladd_float(x, y, Single32(z))
muladd(x::Single32, y::Float32, z::Single32) = muladd_float(x, Single32(y), z)
muladd(x::Float32, y::Single32, z::Single32) = muladd_float(Single32(x), y, z)

muladd(x::Single32, y::Float32, z::Float32) = muladd_float(x, Single32(y), Single32(z))
muladd(x::Float32, y::Single32, z::Float32) = muladd_float(Single32(x), y, Single32(z))
muladd(x::Float32, y::Float32, z::Single32) = muladd_float(Single32(x), Single32(y), z)


# unary
for Op in (:+, :cbrt, :rad2deg, :deg2rad, :mod2pi, :rem2pi, :abs, :abs2, :sign)
    @eval $Op(x::Single32) = Single32($Op(Float64(x)))
end
for Op in (:exp2, :exp10, :expm1, :log2, :log10, :log1p)
    @eval $Op(x::Single32) = Single32($Op(Float64(x)))
end
# binary
for Op in (:\, :^, :div, :rem, :fld, :mod, :cld, :hypot, :min, :max, :minmax, :divrem, :fldmod, :copysign, :flipsign)
    @eval $Op(x::Single32, y::Single32) = Single32($Op(Float64(x), Float64(y)))
end
# trinary
for Op in (:clamp,)
    @eval $Op(x::Single32, y::Single32, z::Single32) = Single32($Op(Float64(x), Float64(y), Float64(z)))
end

Base.fma(x::Single32, y::Single32, z::Single32) = Single32(fma(Float64(x), Float64(y), Float64(z)))
Base.fma(x::Single32, y::Single32, z::T) where {T<:IEEEFloat} = Single32(fma(Float64(x), Float64(y), Float64(z)))
Base.fma(x::Single32, y::T, z::Single32) where {T<:IEEEFloat} = Single32(fma(Float64(x), Float64(y), Float64(z)))
Base.fma(x::T, y::Single32, z::Single32) where {T<:IEEEFloat} = Single32(fma(Float64(x), Float64(y), Float64(z)))
Base.fma(x::Single32, y::T, z::T) where {T<:IEEEFloat} = Single32(fma(Float64(x), Float64(y), Float64(z)))
Base.fma(x::T, y::Single32, z::T) where {T<:IEEEFloat} = Single32(fma(Float64(x), Float64(y), Float64(z)))
Base.fma(x::T, y::T, z::Single32) where {T<:IEEEFloat} = Single32(fma(Float64(x), Float64(y), Float64(z)))


for Op in (:sqrt, :exp, :log,
           :sin, :cos, :tan, :csc, :sec, :cot, 
           :asin, :acos, :atan, :acsc, :asec, :acot,            
           :sinh, :cosh, :tanh, :csch, :sech, :coth, 
           :asinh, :acosh, :atanh, :acsch, :asech, :acoth)
    @eval $Op(x::Single32) = Single32($Op(Float64(x)))
end
