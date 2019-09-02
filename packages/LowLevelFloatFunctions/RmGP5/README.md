# LowLevelFloatFunctions.jl

### Manipulate sign, exponent, significand of Float64, Float32, Float16 values.

> These functions allow you to alter each floating point field individually    
(get, modify, replace) while the rest of the floating point value’s bits    
are unmodified. As the system floats are immutable, replacing a subfield    
actually generates a new float with the bit logic as above.

#### Copyright &copy; 2017 by Jeffrey Sarnoff.  Released under The MIT License.

[![Travis](https://travis-ci.org/JeffreySarnoff/LowLevelFloatFunctions.jl.svg?branch=master)](https://travis-ci.org/JeffreySarnoff/LowLevelFloatFunctions.jl)
-------

**This is for you.** 

*It would be helpful to know what use is made -- Issue 1 is to let me know.*

-----

## Exports

#### value extraction

sign, exponent, significand

#### field getting and setting

sign_field, exponent_field, signficand_field,     
unbiased_exponent_field, biased_exponent_field,    
sign_and_exponent_fields, exponent_and_significand_fields

#### characterization

sign_bits, exponent_bits, significand_bits,           
exponent_max, exponent_min, exponent_field_max,        
exponent_bias    

#### utilitiarian

bitwidth, hexstring    

## Use

These values are used below.

```julia
julia> sqrt2₆₄, sqrt17₆₄ = sqrt(Float64(2)), sqrt(Float64(17))
#> (1.4142_1356_2373_0951, 4.1231_0562_5617_6610#> )

julia> sqrt2₃₂, sqrt17₃₂ = sqrt(Float32(2)), sqrt(Float32(17))
#> (1.4142_135f0, 4.1231_055f0)

julia> sqrt2₁₆, sqrt17₁₆ = sqrt(Float16(2)), sqrt(Float16(17))
#> (Float16(1.414), Float16(4.125))
```

#### value extraction

```julia
julia> significand(-sqrt17₆₄),
       significand( sqrt17₃₂),
       significand(-sqrt17₁₆)

#> (-1.0307764064044151, 1.0307764f0, Float16(-1.031))

julia> exponent(-sqrt17₆₄),
       exponent( sqrt17₃₂),
       exponent(-sqrt17₁₆)

#> (2, 2, 2)

julia> biased_exponent(-sqrt17₆₄),    
       biased_exponent( sqrt17₃₂),    
       biased_exponent(-sqrt17₁₆)
 
#> (1025, 129, 17)

julia> sign(-sqrt17₆₄),
       sign( sqrt17₃₂), 
       sign(-sqrt17₁₆)

#> (-1.0, 1.0f0, Float16(-1.0))
```
#### field getting
```julia
julia> significand_field(sqrt2₆₄),
       significand_field(sqrt2₃₂),
       significand_field(sqrt2₁₆)

#> (0x0006a09e667f3bcd, 0x003504f3, 0x01a8)

julia> biased_exponent_field(-sqrt17₆₄),
       biased_exponent_field(sqrt17₃₂),    
       biased_exponent_field(-sqrt17₁₆)

#> (0x0000000000000401, 0x00000081, 0x0011) 

julia> unbiased_exponent_field(-sqrt17₆₄),
       unbiased_exponent_field( sqrt17₃₂),    
       unbiased_exponent_field(-sqrt17₁₆)

#> (0x0000000000000002, 0x00000002, 0x0002)

julia> sign_field(-sqrt17₆₄),
       sign_field( sqrt17₃₂),
       sign_field(-sqrt17₁₆)

#> (0x0000000000000001, 0x00000000, 0x0001)
```
#### field setting
```julia
julia> sign_field(-sqrt2₆₄, 0%UInt64)
#> 1.4142135623730951

julia> exponent_field(sqrt2₆₄, exponent_field(sqrt2₆₄)+one(UInt64))
#> 2.8284271247461903

julia> ans/2
#> 1.4142135623730951

julia> significand_field(sqrt2₃₂, significand_field(sqrt2₃₂) - one(UInt32)),
       significand_field(sqrt2₃₂, significand_field(sqrt2₃₂)),
       significand_field(sqrt2₃₂, significand_field(sqrt2₃₂) + one(UInt32))

#> (1.4142134f0, 1.4142135f0, 1.4142137f0)

julia> prevfloat(sqrt2₃₂), sqrt2₃₂, nextfloat(sqrt2₃₂)
#> (1.4142134f0, 1.4142135f0, 1.4142137f0)
```
#### characterization
```julia
julia> sign_bits(Float64),
       exponent_bits(Float32),
       significand_bits(Float16)

#> (1, 8, 10)

julia> exponent_min(Float64),
       exponent_max(Float64),
       exponent_field_max(Float64)

#> #> (-1022, 1023, 0x0000000000000400)

julia> exponent_bias(Float32)
#> 1023
```
#### utilitiarian
```julia
julia> bitwidth(Float64), bitwidth(Float32)
#> (64, 32)

julia> hexstring(sqrt2₆₄), hexstring(sqrt2₃₂)
#> ("3ff6a09e667f3bcd", "3fb504f3")
```
