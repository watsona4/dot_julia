primitive type Single32 <: AbstractFloat 64 end

Single32(x::Single32) = x

Single32(x::Float64)  = reinterpret(Single32, x)
Single32(x::Float32)  = Core.Intrinsics.fpext(Single32, x)
Single32(x::Float16)  = reinterpret(Single32, Float64(x))
Single32(x::BigFloat) = Single32(Float64(x))
Single32(x::BigInt)   = Single32(Float64(x))

Base.Float64(x::Single32) = reinterpret(Float64, x)
Base.Float32(x::Single32) = Core.Intrinsics.fptrunc(Float32, x)
Base.Float16(x::Single32) = Float16(Float32(x))

for st in (Int8, Int16, Int32, Int64)
    @eval begin
        (::Type{Single32})(x::($st)) = Core.Intrinsics.sitofp(Single32, x)
        promote_rule(::Type{Single32}, ::Type{$st}) = Single32
    end
end
for ut in (Bool, UInt8, UInt16, UInt32, UInt64)
    @eval begin
        (::Type{Single32})(x::($ut)) = Core.Intrinsics.uitofp(Single32, x)
        promote_rule(::Type{Single32}, ::Type{$ut}) = Single32
    end
end

for T in (Int128, UInt128)
  @eval begin
     promote_rule(::Type{Single32}, ::Type{$T}) = Single32
     Single32(x::$T) = Single32(Float64(x))
   end
end

Bool(x::Single32) = x==0 ? false : x==1 ? true : throw(InexactError(:Bool, Bool, x))

Single32(x::Irrational{S}) where S = Single32(Float64(x))

Single32(x::Complex{Float64}) = Single32(Float64(x))
Single32(x::Complex{Float32}) = Single32(Float32(x))

show(io::IO, x::Single32) = show(io, Float32(x))
string(x::Single32) = string(Float32(x))
repr(x::Single32) = string("Single32(",repr(Float64(x)),")")

widen(::Type{Single32}) = Float64
widen(x::Single32) = Float64(x)

hash(x::Single32) = hash(Float64(x))
hash(x::Single32, h::UInt64) = hash(Float64(x), h)


maxintfloat(::Type{Single32}) = maxintfloat(Float32)
maxintfloat(::Type{Single32}, ::Type{I}) where {I<:Integer} = maxintfloat(Float32, I)

signbit(x::Single32) = signbit(Float64(x))

zero(::Type{Single32}) = Single32(zero(Float64))
one(::Type{Single32}) = Single32(one(Float64))
iszero(x::Single32) = iszero(Float64(x))
isone(x::Single32) = isone(Float64(x))
isinteger(x::Single32) = isinteger(Float32(x))

prevfloat(x::Single32, n::Int) = Single32(prevfloat(Float32(x), n))
nextfloat(x::Single32, n::Int) = Single32(nextfloat(Float32(x), n))


typemin(::Type{Single32})  = typemin(Float32)
typemax(::Type{Single32})  = typemax(Float32)
floatmin(::Type{Single32}) = floatmin(Float32)
floatmax(::Type{Single32}) = floatmax(Float32)
typemin(x::Single32)  = typemin(Single32)
typemax(x::Single32)  = typemax(Single32)
floatmin(x::Single32) = floatmin(Single32)
floatmax(x::Single32) = floatmax(Single32)

eps(::Type{Single32}) = eps(Float32)
eps(x::Single32) = eps(Float32(x))
exponent(x::Single32) = exponent(Float64(x))
significand(x::Single32) = significand(Float64(x))
precision(::Type{Single32}) = precision(Float64)

trunc(x::Single32) = trunc(Float64(x))
floor(x::Single32) = floor(Float64(x))
ceil(x::Single32)  = ceil(Float64(x))

round(x::Single32, r::RoundingMode{:ToZero})  = trunc(Float64(x))
round(x::Single32, r::RoundingMode{:Down})    = floor(Float64(x))
round(x::Single32, r::RoundingMode{:Up})      = ceil(Float64(x))
round(x::Single32, r::RoundingMode{:Nearest}) = round(Float64(x))

trunc(::Type{I}, x::Single32) where {I<:Integer} = trunc(I, Float64(x))
floor(::Type{I}, x::Single32) where {I<:Integer} = floor(I, Float64(x))
ceil(::Type{I}, x::Single32)  where {I<:Integer} = ceil(I, Float64(x))

round(::Type{I}, x::Single32, r::RoundingMode{:ToZero})  where {I<:Integer} = trunc(I, Float64(x))
round(::Type{I}, x::Single32, r::RoundingMode{:Down})    where {I<:Integer} = floor(I, Float64(x))
round(::Type{I}, x::Single32, r::RoundingMode{:Up})      where {I<:Integer} = ceil(I, Float64(x))
round(::Type{I}, x::Single32, r::RoundingMode{:Nearest}) where {I<:Integer} = round(I, Float64(x))
round(::Type{I}, x::Single32) where {I<:Integer} = round(I, Float64(x))


Base.BigFloat(x::Single32) = BigFloat(Float64(x))
Base.Int128(x::Single32) = Int128(Float64(x))
Base.Int64(x::Single32) = Int64(Float64(x))
Base.Int32(x::Single32) = Int32(Float64(x))
Base.Int16(x::Single32) = Int16(Float64(x))

promote_rule(::Type{Single32}, ::Type{Float32}) = Single32
promote_rule(::Type{Single32}, ::Type{Float64}) = Single32


for T in (BigFloat, Float64, Float32, Float16,
          Int128, Int64, Int32, Int16, Int8,
          UInt128, UInt64, UInt32, UInt16, UInt8)
  @eval begin
    convert(::Type{Single32}, x::$T) = Single32(x)
    convert(::Type{$T}, x::Single32) = ($T)(x)
  end
end

Single32(x::Rational{T}) where {T} = Single32(Float64(x))
Rational{T}(x::Single32; tol=eps(x)) where {T} = Rational{T}(rationalize(Float64(x), tol=tol))

promote_rule(::Type{Single32}, ::Type{Rational}) = Single32
convert(::Type{Single32}, x::Rational) = Single32(x)

# comparison

==(x::Single32, y::Single32) = Float32(x) === Float32(y)
==(x::Single32, y::Float64)  = Float64(x) === y
==(x::Float64, y::Single32)  = x === Float64(y)
!=(x::Single32, y::Single32) = Float32(x) !== Float32(y)
!=(x::Single32, y::Float64)  = Float64(x) !== y
!=(x::Float64, y::Single32)  = x !== Float64(y)
<( x::Single32, y::Single32) = Float32(x) < Float32(y)
<( x::Single32, y::Float64)  = Float64(x) < y
<( x::Float64, y::Single32)  = x < Float64(y)
<=(x::Single32, y::Single32) = Float32(x) <= Float32(y)
<=(x::Single32, y::Float64)  = Float64(x) <= y
<=(x::Float64, y::Single32)  = x <= Float64(y)

isequal(x::Single32, y::Single32) = isequal(Float32(x), Float32(y))
isequal(x::Single32, y::Float64)  = isequal(Float64(x), y)
isequal(x::Float64, y::Single32)  = isequal(x, Float64(y))
isless( x::Single32, y::Single32) = isless(Float32(x), Float32(y))
isless( x::Single32, y::Float64)  = isless(Float64(x), y)
isless( x::Float64, y::Single32)  = isless(x, Float64(y))

==(x::Single32, y::Float32)  = Float32(x) === y
==(x::Float32, y::Single32)  = x === Float32(y)
!=(x::Single32, y::Float32)  = Float32(x) !== y
!=(x::Float32, y::Single32)  = x !== Float32(y)
<( x::Single32, y::Float32)  = Float32(x) < y
<( x::Float32, y::Single32)  = x < Float32(y)
<=(x::Single32, y::Float32)  = Float32(x) <= y
<=(x::Float32, y::Single32)  = x <= Float32(y)

isequal(x::Single32, y::Float32)  = isequal(Float32(x), y)
isequal(x::Float32, y::Single32)  = isequal(x, Float32(y))
isless( x::Single32, y::Float32)  = isless(Float32(x), y)
isless( x::Float32, y::Single32)  = isless(x, Float32(y))

for Op in (:cmp, :(==), :(!=), :(>=), :(<=), :(>), :(<), :isless, :isequal)
    @eval begin
        $Op(x::Single32, y::Float16) = $Op(Float64(x), Float64(y))
        $Op(x::Float16, y::Single32) = $Op(Float64(x), Float64(y))

        $Op(x::Single32, y::BigFloat) = $Op(Float64(x), y)
        $Op(x::BigFloat, y::Single32) = $Op(x, Float64(y))

        $Op(x::Single32, y::Int128) = $Op(Float64(x), y)
        $Op(x::Int128, y::Single32) = $Op(x, Float64(y))
        $Op(x::Single32, y::Int64)  = $Op(Float64(x), y)
        $Op(x::Int64, y::Single32)  = $Op(x, Float64(y))
        $Op(x::Single32, y::Int32)  = $Op(Float64(x), y)
        $Op(x::Int32, y::Single32)  = $Op(x, Float64(y))
        $Op(x::Single32, y::Int16)  = $Op(Float64(x), y)
        $Op(x::Int16, y::Single32)  = $Op(x, Float64(y))

        $Op(x::Single32, y::UInt128) = $Op(Float64(x), y)
        $Op(x::UInt128, y::Single32) = $Op(x, Float64(y))
        $Op(x::Single32, y::UInt64)  = $Op(Float64(x), y)
        $Op(x::UInt64, y::Single32)  = $Op(x, Float64(y))
        $Op(x::Single32, y::UInt32)  = $Op(Float64(x), y)
        $Op(x::UInt32, y::Single32)  = $Op(x, Float64(y))
        $Op(x::Single32, y::UInt16)  = $Op(Float64(x), y)
        $Op(x::UInt16, y::Single32)  = $Op(x, Float64(y))
    end
end

decompose(x::Single32) = decompose(Float32(x))
