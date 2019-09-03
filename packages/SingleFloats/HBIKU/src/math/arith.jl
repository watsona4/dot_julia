-(x::Single32) = Single32(-Float64(x))
inv(x::Single32) = Single32(inv(Float64(x)))

+(x::Single32, y::Single32) = Single32(Float64(x) + Float64(y))
-(x::Single32, y::Single32) = Single32(Float64(x) + Float64(y))
*(x::Single32, y::Single32) = Single32(Float64(x) + Float64(y))
/(x::Single32, y::Single32) = Single32(Float64(x) + Float64(y))

+(x::Single32, y::Float64) = Single32(Float64(x) + y)
-(x::Single32, y::Float64) = Single32(Float64(x) + y)
*(x::Single32, y::Float64) = Single32(Float64(x) + y)
/(x::Single32, y::Float64) = Single32(Float64(x) + y)

+(x::Float64, y::Single32) = Single32(x + Float64(y))
-(x::Float64, y::Single32) = Single32(x + Float64(y))
*(x::Float64, y::Single32) = Single32(x + Float64(y))
/(x::Float64, y::Single32) = Single32(x + Float64(y))

+(x::Single32, y::Float32) = Single32(Float64(x) + Float64(y))
-(x::Single32, y::Float32) = Single32(Float64(x) + Float64(y))
*(x::Single32, y::Float32) = Single32(Float64(x) + Float64(y))
/(x::Single32, y::Float32) = Single32(Float64(x) + Float64(y))

+(x::Float32, y::Single32) = Single32(Float64(x) + Float64(y))
-(x::Float32, y::Single32) = Single32(Float64(x) + Float64(y))
*(x::Float32, y::Single32) = Single32(Float64(x) + Float64(y))
/(x::Float32, y::Single32) = Single32(Float64(x) + Float64(y))


muladd(x::Single32, y::Single32, z::Single32) = Single32(muladd(Float64(x), Float64(y), Float64(z)))
muladd(x::Single32, y::Single32, z::Float64) = Single32(muladd(Float64(x), Float64(y), z))
muladd(x::Single32, y::Float64, z::Single32) = Single32(muladd(Float64(x), y, Float64(z)))
muladd(x::Float64, y::Single32, z::Single32) = Single32(muladd(x, Float64(y), Float64(z)))
muladd(x::Single32, y::Float64, z::Float64) = Single32(muladd(Float64(x), y, z))
muladd(x::Float64, y::Single32, z::Float64) = Single32(muladd(x, Float64(y), z))
muladd(x::Float64, y::Float64, z::Single32) = Single32(muladd(x, y, Float64(z)))

fma(x::Single32, y::Single32, z::Single32) = Single32(fma(Float64(x), Float64(y), Float64(z)))
fma(x::Single32, y::Single32, z::Float64) = Single32(fma(Float64(x), Float64(y), z))
fma(x::Single32, y::Float64, z::Single32) = Single32(fma(Float64(x), y, Float64(z)))
fma(x::Float64, y::Single32, z::Single32) = Single32(fma(x, Float64(y), Float64(z)))
fma(x::Single32, y::Float64, z::Float64) = Single32(fma(Float64(x), y, z))
fma(x::Float64, y::Single32, z::Float64) = Single32(fma(x, Float64(y), z))
fma(x::Float64, y::Float64, z::Single32) = Single32(fma(x, y, Float64(z)))

muladd(x::Single32, y::Single32, z::Float32) = Single32(muladd(Float64(x), Float64(y), Float64(z)))
muladd(x::Single32, y::Float32, z::Single32) = Single32(muladd(Float64(x), Float64(y), Float64(z)))
muladd(x::Float32, y::Single32, z::Single32) = Single32(muladd(Float64(x), Float64(y), Float64(z)))
muladd(x::Single32, y::Float32, z::Float32) = Single32(muladd(Float64(x), Float64(y), Float64(z)))
muladd(x::Float32, y::Single32, z::Float32) = Single32(muladd(Float64(x), Float64(y), Float64(z)))
muladd(x::Float32, y::Float32, z::Single32) = Single32(muladd(Float64(x), Float64(y), Float64(z)))

fma(x::Single32, y::Single32, z::Float32) = Single32(fma(Float64(x), Float64(y), Float64(z)))
fma(x::Single32, y::Float32, z::Single32) = Single32(fma(Float64(x), Float64(y), Float64(z)))
fma(x::Float32, y::Single32, z::Single32) = Single32(fma(Float64(x), Float64(y), Float64(z)))
fma(x::Single32, y::Float32, z::Float32) = Single32(fma(Float64(x), Float64(y), Float64(z)))
fma(x::Float32, y::Single32, z::Float32) = Single32(fma(Float64(x), Float64(y), Float64(z)))
fma(x::Float32, y::Float32, z::Single32) = Single32(fma(Float64(x), Float64(y), Float64(z)))

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
