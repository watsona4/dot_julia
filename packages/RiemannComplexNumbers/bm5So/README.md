# The `RiemannComplexNumbers` module


[![Build Status](https://travis-ci.org/scheinerman/RiemannComplexNumbers.jl.svg?branch=master)](https://travis-ci.org/scheinerman/RiemannComplexNumbers.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/RiemannComplexNumbers.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/RiemannComplexNumbers.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/RiemannComplexNumbers.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/RiemannComplexNumbers.jl?branch=master)


This Julia module gives an alternative to `Complex` numbers and their
operations to give mathematically more sensible results.

## The Complex Problem

Standard complex field operations in Julia work fine; the problems
begin to arise when dividing by zero. It is logical to extend the real
numbers with a positive infinity and a negative infinity. And we have
both `+Inf` and `-Inf` in Julia. However, there are problems with the
implementation of infinite values for Julia `Complex` numbers. Here
are some examples.

```julia
# For real numbers, division by 0 gives an infinite result
julia> 1/0
Inf

# This division by 0 for complex numbers is fine
julia> (2+3im)/0
Inf + Inf*im

# But this one doesn't make sense
julia> 2im/0
NaN + Inf*im

# For real numbers we have the following sensible result
julia> (Inf + 3) == (Inf + 2)
true

# But it breaks for complex numbers
julia> (Inf + 3im) == (Inf + 2im)
false
```

## This Solution

This module defines an alternative to `Complex` numbers in which there is a
single infinite value (we call `ComplexInfinity`). We introduce a new type
called `RC` (an abbreviation for Riemann Complex number). Let's see how the
previous calculations work in this new context:

```julia
julia> using RiemannComplexNumbers

julia> (2+3IM)/0
ComplexInf

julia> 2IM/0
ComplexInf

julia> Inf + 3IM == Inf + 2IM
true
```

The constant `IM` is the replacement for `im` that can be used to construct
Riemann Complex numbers. In general, wrapping values in `RC` will work:
```julia
julia> RC(2)
2 + 0IM

julia> RC(3-im)
3 - 1IM
```

Dividing by zero gives the following:
```julia
julia> (2-3IM)/0
ComplexInf

julia> 3/0IM
ComplexInf

julia> 0/0IM
ComplexNaN
```

To convert an `RC` number to a `Complex` do this:
```julia
julia> z = 3.5 - 5IM
3.5 - 5.0IM

julia> Complex(z)
3.5 - 5.0im
```

Basic arithmetic operations work exactly the same for `RC` numbers as for `Complex`
but will be slower (to deal with division by zero and operations with `ComplexInf`
and `ComplexNaN`).

Some basic functions (such as `sqrt` and `exp`) are provided. See the `functions.jl`
file in the `src` directory.

## To Do

Some `LinearAlgebra` operations don't work; I'm not sure why. For example,
evaluating the determinant of an `RC` matrix throws errors.
