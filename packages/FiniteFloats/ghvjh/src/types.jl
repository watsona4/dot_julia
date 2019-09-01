abstract type AbstractFinite <: AbstractFloat end

primitive type Finite64 <: AbstractFinite 64 end
primitive type Finite32 <: AbstractFinite 32 end
primitive type Finite16 <: AbstractFinite 16 end


@inline function FiniteFloat64(x::Float64)
    isfinite(x) && return x
    if isinf(x)
       signbit(x) ? Finite64_maxneg : Finite64_maxpos
    else
       throw(DomainError("NaN encountered"))
    end
end

@inline function FiniteFloat32(x::Float32)
    isfinite(x) && return x
    if isinf(x)
       signbit(x) ? Finite32_maxneg : Finite32_maxpos
    else
       throw(DomainError("NaN32 encountered"))
    end
end

@inline function FiniteFloat16(x::Float16)
    isfinite(x) && return x
    if isinf(x)
       signbit(x) ? Finite16_maxneg : Finite16_maxpos
    else
       throw(DomainError("NaN16 encountered"))
    end
end


Finite64(x::Float64) = reinterpret(Finite64, FiniteFloat64(x))
Finite32(x::Float32) = reinterpret(Finite32, FiniteFloat32(x))
Finite16(x::Float16) = reinterpret(Finite16, FiniteFloat16(x))

Float64(x::Finite64) = reinterpret(Float64, x)
Float32(x::Finite32) = reinterpret(Float32, x)
Float16(x::Finite16) = reinterpret(Float16, x)

Float64(x::Finite32) = reinterpret(Float64, Finite64(x))
Float64(x::Finite16) = reinterpret(Float64, Finite64(x))
Float32(x::Finite16) = reinterpret(Float32, Finite32(x))


float(::Type{Finite64}) = Float64
float(::Type{Finite32}) = Float32
float(::Type{Finite16}) = Float16

finite(::Type{Float64}) = Finite64
finite(::Type{Float32}) = Finite32
finite(::Type{Float16}) = Finite16

finite(::Type{Int64}) = Finite64
finite(::Type{Int32}) = Finite32
finite(::Type{Int16}) = Finite16

signed(::Type{Finite64}) = Int64
signed(::Type{Finite32}) = Int32
signed(::Type{Finite16}) = Int16

finite(::Type{UInt64}) = Finite64
finite(::Type{UInt32}) = Finite32
finite(::Type{UInt16}) = Finite16

unsigned(::Type{Finite64}) = UInt64
unsigned(::Type{Finite32}) = UInt32
unsigned(::Type{Finite16}) = UInt16

typemax(::Type{Finite64})    = Finite64(1.7976931348623157e308)     #  realmax(Float64)
typemax(::Type{Finite32})    = Finite32(3.4028235f38)               #  realmax(Float32)
typemax(::Type{Finite16})    = Finite16(Float16(6.55e4))            #  realmax(Float16)
typemaxneg(::Type{Finite64}) = Finite64(-1.7976931348623157e308)    # -realmax(Float64) 
typemaxneg(::Type{Finite32}) = Finite32(-3.4028235f38)              # -realmax(Float32)
typemaxneg(::Type{Finite16}) = Finite16(Float16(-6.55e4))           # -realmax(Float16)

typemin(::Type{Finite64})    = Finite64(2.2250738585072014e-308)    #  realmin(Float64)
typemin(::Type{Finite32})    = Finite32(1.1754944f-38)              #  realmin(Float32)
typemin(::Type{Finite16})    = Finite16(Float16(6.104e-5))          #  realmin(Float16)
typeminneg(::Type{Finite64}) = Finite64(-2.2250738585072014e-308)   # -realmin(Float64) 
typeminneg(::Type{Finite32}) = Finite32(-1.1754944f-38)             # -realmin(Float32)
typeminneg(::Type{Finite16}) = Finite16(Float16(-6.104e-5))         # -realmin(Float16)

floatmax(::Type{Finite64}) = typemax(Finite64)
floatmax(::Type{Finite32}) = typemax(Finite32)
floatmax(::Type{Finite16}) = typemax(Finite16)
floatmin(::Type{Finite64}) = typemin(Finite64)
floatmin(::Type{Finite32}) = typemin(Finite32)
floatmin(::Type{Finite16}) = typemin(Finite16)

# consts are used to accelerate replacement of infinities
const Finite64_maxpos = typemax(Finite64)
const Finite64_minpos = typemin(Finite64)
const Finite64_maxneg = typemaxneg(Finite64)
const Finite64_minneg = typeminneg(Finite64)
const Finite32_maxpos = typemax(Finite32)
const Finite32_minpos = typemin(Finite32)
const Finite32_maxneg = typemaxneg(Finite32)
const Finite32_minneg = typeminneg(Finite32)
const Finite16_maxpos = typemax(Finite16)
const Finite16_minpos = typemin(Finite16)
const Finite16_maxneg = typemaxneg(Finite16)
const Finite16_minneg = typeminneg(Finite16)

for O in ( :(-), :(+),
           :string,
           :sign,
           :prevfloat, :nextfloat,
           :round, :trunc, :ceil, :floor,
           :inv, :abs, :sqrt, :cbrt,
           :exp, :expm1, :exp2, :exp10,
           :log, :log1p, :log2, :log10,
           :rad2deg, :deg2rad, :mod2pi, :rem2pi,
           :sin, :cos, :tan, :csc, :sec, :cot,
           :asin, :acos, :atan, :acsc, :asec, :acot,
           :sinh, :cosh, :tanh, :csch, :sech, :coth,
           :asinh, :acosh, :atanh, :acsch, :asech, :acoth,
           :sinc, :sinpi, :cospi,
           :sind, :cosd, :tand, :cscd, :secd, :cotd,
           :asind, :acosd, :atand, :acscd, :asecd, :acotd
          )       
    @eval begin
        $O(x::Finite64) = Finite64($O(Float64(x))) 
        $O(x::Finite32) = Finite32($O(Float32(x))) 
        $O(x::Finite16) = Finite16($O(Float16(x))) 
    end
end

for (T,F) in ( (:Finite64, :Float64), (:Finite32, :Float32), (:Finite16, :Float16) )
   @eval begin
       Base.String(x::$T) = String($F(x))
       $T(x::String) = $T(parse($F, x))
       Base.show(io::IO, x::$T) = show(io, $F(x))
       square(x::$T) = $T($F(x)*$F(x))
       cube(x::$T) = $T($F(x)*$F(x)*$F(x))              
   end
end



for O in ( :flipsign, :copysign,
           :min, :max, 
           :(+), :(-), :(*), :(/), :(^),  
           :div, :rem, :fld, :mod, :cld,
           :hypot 
          )       
    @eval begin
        $O(x::Finite64, y::Finite64) = Finite64($O(Float64(x), Float64(y))) 
        $O(x::Finite32, y::Finite32) = Finite32($O(Float32(x), Float32(y))) 
        $O(x::Finite16, y::Finite16) = Finite16($O(Float16(x), Float16(y))) 
    end
end

for O in ( :(==), :(!=),
           :(<), :(<=), :(>=), :(>),  
           :isequal, :isless
          )       
    @eval begin
        $O(x::Finite64, y::Finite64) = $O(Float64(x), Float64(y)) 
        $O(x::Finite32, y::Finite32) = $O(Float32(x), Float32(y)) 
        $O(x::Finite16, y::Finite16) = $O(Float16(x), Float16(y)) 
    end
end

signbit(x::Finite64) = signbit(Float64(x))
signbit(x::Finite32) = signbit(Float32(x))
signbit(x::Finite16) = signbit(Float16(x))

for O in ( :minmax, :modf )       
    @eval begin
        $O(x::Finite64, y::Finite64) = Finite64.($O(Float64(x), Float64(y))) 
        $O(x::Finite32, y::Finite32) = Finite32.($O(Float32(x), Float32(y))) 
        $O(x::Finite16, y::Finite16) = Finite16.($O(Float16(x), Float16(y)))
    end
end

frexp(x::Finite64) = map((a,b)->(Finite64(a), b), frexp(Float64(x))...,)
frexp(x::Finite32) = map((a,b)->(Finite32(a), b), frexp(Float32(x))...,)
frexp(x::Finite16) = map((a,b)->(Finite16(a), b), frexp(Float16(x))...,)

ldexp(x::Finite64, y::Int) = Finite64(ldexp(Float64(x), y))
ldexp(x::Finite32, y::Int) = Finite32(ldexp(Float32(x), y))
ldexp(x::Finite16, y::Int) = Finite16(ldexp(Float16(x), y))

sincos(x::Finite64) = map((a,b)->(Finite64(a), Finite64(b)), sincos(Float64(x))...,)
sincos(x::Finite32) = map((a,b)->(Finite32(a), Finite32(b)), sincos(Float32(x))...,)
sincos(x::Finite16) = map((a,b)->(Finite16(a), Finite16(b)), sincos(Float16(x))...,)

clamp(x::T, lo::T, hi::T) where {T<:Finite64} = Finite64(clamp(Float64(x), Float64(lo), Float64(hi)))

for (T,F) in ( (:Finite64, :Float64), (:Finite32, :Float32), (:Finite16, :Float16) )
   @eval begin
       clamp(x::$T, lo::$T, hi::$T) = $T( clamp($F(x), $F(lo), $F(hi)) )
   end
end



Base.promote_rule(::Type{Float64}, ::Type{Finite64}) = Finite64
Base.promote_rule(::Type{Float32}, ::Type{Finite32}) = Finite32
Base.promote_rule(::Type{Float16}, ::Type{Finite16}) = Finite16

Base.promote_rule(::Type{Finite64}, ::Type{Finite32}) = Finite64
Base.promote_rule(::Type{Finite64}, ::Type{Finite16}) = Finite64
Base.promote_rule(::Type{Finite32}, ::Type{Finite16}) = Finite32

Finite64(x::Finite32) = Finite64(Float64(Float32(x)))
Finite64(x::Finite16) = Finite64(Float64(Float16(x)))
Finite32(x::Finite64) = Finite32(Float32(Float64(x)))
Finite32(x::Finite16) = Finite32(Float32(Float16(x)))
Finite16(x::Finite64) = Finite16(Float16(Float64(x)))
Finite16(x::Finite16) = Finite16(Float16(Float16(x)))

Base.promote_rule(::Type{Float32}, ::Type{Finite64}) = Finite64
Base.promote_rule(::Type{Float16}, ::Type{Finite64}) = Finite64
Base.promote_rule(::Type{Float16}, ::Type{Finite32}) = Finite32
Base.promote_rule(::Type{Float64}, ::Type{Finite32}) = Finite64
Base.promote_rule(::Type{Float64}, ::Type{Finite16}) = Finite64
Base.promote_rule(::Type{Float32}, ::Type{Finite16}) = Finite32

Finite64(x::Float32) = Finite64(Float64(x))
Finite64(x::Float16) = Finite64(Float64(x))
Finite32(x::Float64) = Finite32(Float32(x))
Finite32(x::Float16) = Finite32(Float32(x))
Finite16(x::Float64) = Finite16(Float16(x))
Finite16(x::Float32) = Finite16(Float16(x))

Base.promote_rule(::Type{Int64}, ::Type{Finite64}) = Finite64
Base.promote_rule(::Type{Int32}, ::Type{Finite32}) = Finite32
Base.promote_rule(::Type{Int16}, ::Type{Finite16}) = Finite16

Base.promote_rule(::Type{Int32}, ::Type{Finite64}) = Finite64
Base.promote_rule(::Type{Int16}, ::Type{Finite64}) = Finite64
Base.promote_rule(::Type{Int16}, ::Type{Finite32}) = Finite32
Base.promote_rule(::Type{Int64}, ::Type{Finite32}) = Finite64
Base.promote_rule(::Type{Int64}, ::Type{Finite16}) = Finite64
Base.promote_rule(::Type{Int32}, ::Type{Finite16}) = Finite32

Finite64(x::Int64) = Finite64(Float64(x))
Finite64(x::Int32) = Finite64(Float64(x))
Finite64(x::Int16) = Finite64(Float64(x))
Finite32(x::Int64) = Finite32(Float32(x))
Finite32(x::Int32) = Finite32(Float32(x))
Finite32(x::Int16) = Finite32(Float32(x))
Finite16(x::Int64) = Finite16(Float16(x))
Finite16(x::Int32) = Finite16(Float16(x))
Finite16(x::Int16) = Finite16(Float16(x))

Int64(x::Finite64) = Int64(Float64(x))
Int64(x::Finite32) = Int64(Float64(Float32(x)))
Int64(x::Finite16) = Int64(Float64(Float16(x)))
Int32(x::Finite64) = Int32(Float64(x))
Int32(x::Finite32) = Int32(Float32(x))
Int32(x::Finite16) = Int32(Float16(x))
Int16(x::Finite64) = Int16(Float64(x))
Int16(x::Finite32) = Int16(Float32(x))
Int16(x::Finite16) = Int16(Float16(x))
