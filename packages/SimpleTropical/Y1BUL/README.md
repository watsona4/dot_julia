# SimpleTropical



[![Build Status](https://travis-ci.org/scheinerman/SimpleTropical.jl.svg?branch=master)](https://travis-ci.org/scheinerman/SimpleTropical.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/SimpleTropical.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/SimpleTropical.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/SimpleTropical.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/SimpleTropical.jl?branch=master)



This is an implementation of tropical (min-plus) arithmetic in Julia.

## Numbers

The tropical numbers consist of the real numbers and infinity. The
`SimpleTropical` module defines the `Tropical` type (which is a
subtype of `Number`). Tropical numbers can be parameterized by type,
but this is taken care of automatically:

```julia
julia> using SimpleTropical

julia> x = Tropical(3.5)
Tropical{Float64}(3.5)

julia> y = Tropical{Int}(4)
Tropical{Int64}(4)
```

Tropical infinity is available via `TropicalInf`:
```
julia> TropicalInf
Tropical(∞)
```


## Arithmetic

The `+` operation is defined as the min of the two values and `*`
as the sum:
```julia
julia> x+y
Tropical{Float64}(3.5)

julia> x*y
Tropical{Float64}(7.5)
```

The identity element for `+` is `TropicalInf` and the identity
element for `*` is `Tropical(0)`:
``` julia
julia> x + TropicalInf
Tropical{Float64}(3.5)

julia> x * Tropical(0)
Tropical{Float64}(3.5)
```

No elements in tropical arithmetic have additive inverses, but they
do have multiplicative inverses (except for infinity):
```julia
julia> inv(x)
Tropical{Float64}(-3.5)

julia> inv(TropicalInf)
ERROR: AssertionError: TropicalInf is not invertible
```

Exponentiation by integers works:
```julia
julia> x^10
Tropical{Float64}(35.0)

julia> x^-2
Tropical{Float64}(-7.0)
```

## Predicates

Use `isinf(X)` to test if a tropical number is infinity.
```julia
julia> isinf(x)
false

julia> isinf(TropicalInf)
true
```

The usual comparison operators `==` and `!==` work as expected:
```julia
julia> Tropical(3.0) == Tropical(3)
true

julia> Tropical(3.1) != Tropical(3//1)
true
```

## To do list

+ Make the `Polynomials` module work with tropical numbers.
