# FiniteFloats.jl

#### Floats with neither Infinities nor NaNs.


----

#### Copyright ©&thinsp;2018 by Jeffrey Sarnoff. &nbsp;&nbsp; This work is released under The MIT License.


-----

[![Build Status](https://travis-ci.org/JeffreySarnoff/FiniteFloats.jl.svg?branch=master)](https://travis-ci.org/JeffreySarnoff/FiniteFloats.jl)
----

## Use
```julia

using FiniteFloats

julia> a = sqrt(Finite64(2))
1.4142135623730951

julia> typeof(a)
Finite64

julia> b = Finite32(Inf32)
3.4028235f38

julia> b == typemax(Finite32)
true
```

## Exports

#### exported types

- Finite64, Finite32, Finite16

#### supported functions

In addition to the familiar functions that work with Float64, Float32, Float16,    
(comparisions, floating part decompositions, arithmetic, elementary functions)

-    square, cube

-    string, show, 
-    typemax, typemin, floatmax, floatmin
    
-    significand, exponent, precision
-    prevfloat, nextfloat, isequal, isless
    
-    (==), (!=), (<), (<=), (>=), (>)
-    (+), (-), (*), (/), (^)
    
-    inv, div, rem, fld, mod, cld

-    round, trunc, ceil, floor (single arg forms)
    
-    abs, signbit, copysign, flipsign, sign
-    frexp, ldexp, modf
    
-    min, max, minmax
-    clamp, sqrt, cbrt, hypot
    
-    exp, expm1, exp2, exp10
-    log, log1p, log2, log10
 
-    sin, cos, tan, csc, sec, cot
-    asin, acos, atan, acsc, asec, acot

-    sinh, cosh, tanh, csch, sech, coth,
-    asinh, acosh, atanh, acsch, asech, acoth


-    sind, cosd, tand, cscd, secd, cotd
-    asind, acosd, atand, acscd, asecd, acotd

-    rad2deg, deg2rad, mod2pi, rem2pi
-    sincos, sinc, sinpi, cospi


----

## Examples
```julia
julia> Float64(0) * inv(Float64(0))
NaN

julia> Finite64(0) * inv(Finite64(0))
0.0

julia> typemax(Finite64) == nextfloat(floatmax(Finite64)) == floatmax(Finite64)
true
```

Finite64|32|16 are saturating at ±floatmax(T) 
