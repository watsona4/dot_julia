# Arbitrary

Generate arbitrary sequences for testing.

[![Build Status (Travis)](https://travis-ci.org/eschnett/Arbitrary.jl.svg?branch=master)](https://travis-ci.org/eschnett/Arbitrary.jl)
[![Build status (Appveyor)](https://ci.appveyor.com/api/projects/status/r0ryqdjn2rmhv29w?svg=true)](https://ci.appveyor.com/project/eschnett/arbitrary-jl)
[![Coverage Status (Coveralls)](https://coveralls.io/repos/github/eschnett/Arbitrary.jl/badge.svg?branch=master)](https://coveralls.io/github/eschnett/Arbitrary.jl?branch=master)
[![DOI](https://zenodo.org/badge/146501346.svg)](https://zenodo.org/badge/latestdoi/146501346)

## Overview

The Arbitrary package allows testing properties that must hold for
data types. For example, the `BigInt` implementation needs to ensure
that addition and multiplication are commutative and associative, that
`0` and `1` are the additive and multiplicative identity, etc. In
an ideal world, we would want the compiler to prove that these
properties hold (or at least to verify a human-written proof). In the
real world, we can test these properties hold for "arbitrary"
`BigInt` numbers.

The basic API consists of the function `arbitrary(::Type{T})`, which
returns an iterator that produces values of type `T`. The iterator
will first produce "simple" or "special" values (such as 0 or 1), and
will then go on to produce more "difficult" values via a random number
generator. I expect that testing properties with e.g. 100 such
arbitrary values make for good property tests.

### Example 1:
```Julia
using Base.Iterators
using Test
using Arbitrary
# Generate arbitrary values
xs = collect(take(arbitrary(BigInt), 100))
ys = collect(take(arbitrary(BigInt), 100))
zs = collect(take(arbitrary(BigInt), 100))
# Test commutativity
@test all(xs .+ ys .== ys .+ xs)
# Test associativity
@test all((xs .+ ys) .+ zs .== xs .+ (ys .+ zs))
```

## Why not just use random values?

This package takes its motivation from Haskell's
[`Test.QuickCheck.Arbitrary`](http://hackage.haskell.org/package/QuickCheck-2.11.3/docs/Test-QuickCheck-Arbitrary.html)
type class.

Arbitrary values are quite similar to random values. The main
difference is that one has (better) control over the the probability
with which certain values are produced. This ensures that corner cases
receive proper testing. For example, the default random number
generator for `Int` values creates numbers with a uniform
distribution, and it is thus very unlikely to obtain small integers
(e.g. from 1 to 10).

## Defining `arbitrary` for your own type

The `Arbitrary` package contains methods for various built-in types.
To extend this for your own type, you need to provide a respective
method for the `arbitrary` function.

### Example 2:
```Julia
using Base.Iterators
using Arbitrary
# Define your own type
struct Point{T}
    x::T
    y::T
end
# Define a method for Arbitrary.arbitrary
function Arbitrary.arbitrary(::Type{Point{T}}, ast::ArbState) where {T}
    xs = Iterators.Stateful(arbitrary(T, ast))
    flatten([Point{T}[Point(T(0), T(0)),
                      Point(T(0), T(1)),
                      Point(T(1), T(0)),
                      Point(T(-1), T(-1))],
            Generate{Point{T}}(
                () -> Point(popfirst!(xs), popfirst!(xs)))])
end
```

This `arbitrary` method first generates 4 points with particular
values, which are presumably simple but interesting. Next it uses
existing `arbitrary` methods for the type `T` to generate new
points. `Generate` is a wrapper type that creates an iterator from a
function. The function `Base.Iterators.flatten` concatenates
iterators, while the type `Base.Iterators.Stateful` captures
iterators into mutable objects.

```Julia
julia> collect(take(arbitrary(Point{Int}, UInt(42)), 20))

20-element Array{Point{Int64},1}:
  Point{Int64}(0, 0)                                      
  Point{Int64}(0, 1)                                      
  Point{Int64}(1, 0)                                      
  Point{Int64}(-1, -1)                                    
  Point{Int64}(0, 1)                                      
  Point{Int64}(2, 3)                                      
  Point{Int64}(-1, -2)                                    
  Point{Int64}(10, 100)                                   
  Point{Int64}(-10, 9223372036854775807)                  
  Point{Int64}(9223372036854775806, -9223372036854775808)
  Point{Int64}(-9223372036854775807, 9067366622006296321)
  Point{Int64}(-2256197071093261190, -5795687145721743680)
  Point{Int64}(2798402323870333227, 8156153274284847668)  
  Point{Int64}(8296248152788523164, 2972613083423981281)  
  Point{Int64}(6437123995368952903, -7346326483082348639)
  Point{Int64}(5681684189447142543, 499062510383072047)   
  Point{Int64}(-4069693335803290299, -5159697560496114268)
  Point{Int64}(5657203908704019168, -551782769629649706)  
  Point{Int64}(5497552197468976212, -2695328260518845352)
  Point{Int64}(-1464621002877751017, -7952756775211842320)
```

The generated arbitrary points start out with the four special values
that are specified explicitly, and then continue with arbitrary
`Int` values. If you run this example, then your output will differ
since you will be using a different random number generator seed. You
can explicitly pass in a seed by calling e.g. `arbitrary(Point{Int},
UInt(42))` to ensure reproducible arbitrary sequences.
