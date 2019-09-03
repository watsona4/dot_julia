# StaticUnivariatePolynomials.jl

[![Build Status](https://travis-ci.com/tkoolen/StaticUnivariatePolynomials.jl.svg?branch=master)](https://travis-ci.com/tkoolen/StaticUnivariatePolynomials.jl)
[![Codecov](https://codecov.io/gh/tkoolen/StaticUnivariatePolynomials.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkoolen/StaticUnivariatePolynomials.jl)

StaticUnivariatePolynomials provides a `Polynomial` type representing a dense univariate polynomial. In contrast to e.g. [JuliaMath/Polynomials.jl](https://github.com/JuliaMath/Polynomials.jl), coefficients are stored in an `NTuple`.
This makes `Polynomial` a stack-allocatable bitstype when the coefficient type is a bitstype, enabling high performance.

## Usage

Polynomials may be created by passing in coeffients ordered from lowest to highest degree:

```julia
julia> using StaticUnivariatePolynomials, BenchmarkTools, Test

julia> p = Polynomial(1, 2, 3) # 1 + 2x + 3x^2
Polynomial{3,Int64}((1, 2, 3))
```

The Polynomial type overloads the call operator for evaluation, and is implemented using `Base.@evalpoly` (for real coefficients, using Horner's method):

```julia
julia> p(4)
57
```

Evaluation is fast:

```julia
julia> @btime $p(x) setup = x = rand()

  2.052 ns (0 allocations: 0 bytes)
```

Basic arithmetic is implemented:

```julia
julia> p + 1
Polynomial{3,Int64}((2, 2, 3))

julia> p + Polynomial(3, 2, 1)
Polynomial{3,Int64}((4, 4, 4))

julia> p / 4
Polynomial{3,Float64}((0.25, 0.5, 0.75))

julia> p * p
Polynomial{5,Int64}((1, 4, 10, 12, 9))
```

Calculus:

```julia
julia> import StaticUnivariatePolynomials: derivative, integral

julia> P = integral(p, 5) # integral of p such that P(0) = 5
Polynomial{4,Float64}((5.0, 1.0, 1.0, 1.0))

julia> P′ = derivative(P)
Polynomial{3,Float64}((1.0, 2.0, 3.0))

julia> @test typeof(P′)(p) === P′
Test Passed
```
