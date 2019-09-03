`RandomizedPropertyTest.jl`
---------------------------

`RandomizedPropertyTest.jl` is a test framework for testing program properties with random (as well as special pre-defined) inputs, inspired by [`QuickCheck`](https://github.com/nick8325/quickcheck).

Test status: [![builds.sr.ht status](https://builds.sr.ht/~quf/RandomizedPropertyTest.jl.svg)](https://builds.sr.ht/~quf/RandomizedPropertyTest.jl?)

Examples
--------

The first property we test is that the square of a double-precision floating point number is nonnegative.

```julia
julia> using RandomizedPropertyTest

julia> @quickcheck (x^2 ≥ 0) (x :: Float64)
┌ Warning: Property `x ^ 2 ≥ 0` does not hold for x = NaN.
└ @ RandomizedPropertyTest [snip]/RandomizedPropertyTest.jl:83
false
```

The macro prints a message which gives a failing input: NaN.
After refining the property, the test succeeds:

```jldoctest
julia> using RandomizedPropertyTest

julia> @quickcheck (isnan(x) || x^2 ≥ 0) (x :: Float64)
true
```

The macro returns `true`, which means the property holds for all inputs which were tested.
Because the macro returns a `Bool`, it can be used together with the `@test` macro for automated testing.

Next, we will test Julia's builtin trigonometric functions, for floats inside of a certain range:

```jldoctest
julia> using RandomizedPropertyTest

julia> @quickcheck (sin(x + π/2) ≈ cos(x)) (x :: Range{Float64, 0, 2π})
true
```

Note that ranges are inclusive, and both endpoints are treated as special cases which are always tested.

Tests can use multiple variables.

```
julia> using RandomizedPropertyTest

julia> @quickcheck (a+b == b+a) (a :: Int) (b :: Int)
true
```

There is convenient syntax for declaring multiple variables of the same type.

```jldoctest
julia> using LinearAlgebra, RandomizedPropertyTest

julia> @quickcheck (norm([x,y,z]) ≥ 0 || any(isnan, [x,y,z])) ((x, y, z) :: Float64)
true
```

To increase (or reduce) the number of random tests, we can simply give the number as first argument.

```jldoctest
julia> using RandomizedPropertyTest

julia> @quickcheck n=10^6 (sum(x^k/factorial(k) for k in 20:-1:0) ≈ exp(x)) (x :: Range{Float64, -2, 2})
true
```

At the moment, only numbers and powers of numbers are supported.
Other expressions (including variables) are not supported at this time.

Next, let's test the value of the geometric series for complex numbers inside the unit disk (the boundary is excluded).

```jldoctest
julia> using RandomizedPropertyTest

julia> let nmax(ε, z) = if z == 0; 0 else Int(round(log10(ε)/log10(abs(z)))) end
           @quickcheck sum(z^k for k in nmax(√eps(1.0), z):-1:0) ≈ 1/(1-z) (z :: Disk{Complex{Float64}, 0, 1})
       end
true
```

Support for Arrays is also available:

```jldoctest
julia> using LinearAlgebra, RandomizedPropertyTest

julia> @quickcheck (any(isnan, A) || any(isinf, A) || all(λ->λ≥-0.001, eigvals(Symmetric(A * transpose(A))))) (A :: Array{Float32, 2})
true
```

At this time, support for arrays with more than two dimensions is limited.


Supported Datatypes
-------------------

The following built-in data types have predefined generators:
- `Bool`
- `Int8`, `Int16`, `Int32`, `Int64`, `Int128`
- `UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt128`
- `Float16`, `Float32`, `Float64`
- `Complex{T}` for any `T` for which a generator is defined
- `Array{T,N}` for any `T` for which a generator is defined
- Types for which `rand(rng, T)` is available.

The following additional data types have predefined generators:
- `Range{T,a,b}` where `T` is an `Integer` or an `AbstractFloat` (for which a generator is defined).
  Represents the interval `[a,b]` for variables of type `T`.
- `Disk{Complex{T},z₀,r}` where `T` is an `AbstractFloat` (for which a generator is defined).
  Represents the disk `abs(z-z₀) < r` for variables of type `Complex{T}`.


Custom Distributions or Datatypes
---------------------------------


To use `@quickcheck` with a custom datatype, or to generate random samples from a specific distribution, import and specialize the functions `RandomizedPropertyTest.generate` and `RandomizedPropertyTest.specialcases`.

In this example, we generate floats from the normal distribution.

```
julia> using RandomizedPropertyTest, Random

julia> import RandomizedPropertyTest.specialcases, RandomizedPropertyTest.generate

julia> struct NormalFloat{T}; end # Define a new type; it does not need to be a parametric type.

julia> RandomizedPropertyTest.specialcases(_ :: Type{NormalFloat{T}}) where {T<:AbstractFloat} = RandomizedPropertyTest.specialcases(T) # Inherit special cases from the "regular" type.

julia> RandomizedPropertyTest.generate(rng :: AbstractRNG, _ :: Type{NormalFloat{T}}) where {T<:AbstractFloat} = randn(rng, T) # Define random generation using the normal distribution.

julia> @quickcheck (typeof(x) == Float32) (x :: NormalFloat{Float32}) # Use the new type like the built-in types.
true
```

Note that `specialcases` returns a 1d array of special cases which are always checked.
For multiple variables, every combination of special cases is tested.
Make sure to limit the number of special cases to avoid problems due to combinatorial explosion - for more than one variable, all combinations of all special cases are checked.

The function `generate` should return a single random specimen of the datatype.
Note that it takes an `AbstractRNG` argument.
You do not technically have to use it, but you should.
If you do, this makes tests (and test failures) reproducible, which probably helps debugging.


Bugs and caveats
----------------

- Performance is quite low:
  On the author's laptop, `@quickcheck n=10^7 true (x :: Int)` takes around 5.6 seconds and `@time @quickcheck n=10^7 (a+b == b+a || any(isnan, (a,b)) || all(isinf, (a,b))) ((a,b) :: Float64)` takes around 6.9 seconds.
- Combinatorial explosion of special cases makes working with many variables very difficult.
  For example, using nine `Float64` variables to check properties of 3x3 matrices generates 5*10^9 special cases.
  If you need something like this, consider specialising `RandomizedPropertyTest.generate` for a custom generator datatype instead.
- Testing is not exhaustive:
  You should not rely on `@quickcheck` to test every possible input value, e. g. if the only variable for which you are testing is a small integer range.
- Error messages do not give correct source location information in case of a failure.
  However, if `@quickcheck` is used in conjunction with `@test`, a full stacktrace is given; if it is used interactively, the location should be obvious.
  Further, in both cases the expression is printed.
  This makes the lack of correct location only a minor issue in most cases.


Related work
------------

- [`QuickCheck`](https://github.com/nick8325/quickcheck) (as well as the [original QuickCheck](www.cse.chalmers.se/~rjmh/QuickCheck/)) is a property testing framework (or specification testing framework) for Haskell programs.
  It is great but cannot test Julia programs.
  Hence this project.
- [`Quickcheck.jl`](https://github.com/pao/QuickCheck.jl) is a property testing implementation for Julia programs, also inspired by [`QuickCheck`](https://github.com/nick8325/quickcheck).
  At the time of writing, it seems to be unmaintained since five years and is not compatible with Julia version 1 (though a pull request which fixes this is pending).
  Unlike this package, it does not specifically test special values like NaN or empty arrays.


Version
-------

`RandomizedPropertyTest.jl` follows [semanting versioning v2.0.0](https://semver.org/).
The current version is 0.1.0.


Copying
-------

Copyright © 2019  Lukas Himbert

`RandomizedPropertyTest.jl` is free software:
you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.
If not, see <https://www.gnu.org/licenses/>.


TODO
----

- Write generators and special cases for all the things (see how QuickCheck does it?):
  - square matrices
  - symmetric matrices
  - Hermitian matrices
  - unitary matrices
  - n-tuples
  - strings
  - rational numbers
  - Maybe also for certain distributions: normal, exponential, cauchy, lognormal, ...
  - enumerations
  - union types
  - Finite{T} where {T <: Number}
  - ???
- To test numerical algorithms, there should be convenient syntax to test matrices and vectors of certain corresponding sizes.
  Maybe something like `@quickcheck ((A,v) = x; transpose(v) * A * v ≥ 0) (x :: SymmetricMatrixAndVector{Float64})`.
- Figure out how to achieve parallel checking without losing reproducibility of test cases (fixed large number of independent streams?).
  Also figure out how to make parallel checking convenient (`@parallel @quickcheck expr types`?)


How does it work?
-----------------

Here is a simplified version (mostly for the benefit of the author):

```jldoctest
julia> macro evaluate(expr, argname, arg)
           fexpr = esc(Expr(:(->), argname, expr)) # define a closure in the calling scope
           Expr(:call, fexpr, arg) # call it
       end
@evaluate (macro with 1 method)

julia> y = 2
2

julia> @evaluate (4*x+y) x 10
42
```
