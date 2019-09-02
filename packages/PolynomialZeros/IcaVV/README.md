# PolynomialZeros

Methods to find zeros (roots) of polynomials over given domains

Linux: [![Build Status](https://travis-ci.org/jverzani/PolynomialZeros.jl.svg?branch=master)](https://travis-ci.org/jverzani/PolynomialZeros.jl)

Windows:
[![Build status](https://ci.appveyor.com/api/projects/status/ovkutr0gxrdtjxmb/branch/master?svg=true)](https://ci.appveyor.com/project/jverzani/polynomialzeros-jl/branch/master)



This package provides the method `poly_roots` to find roots of
univariate polynomial functions over the complex numbers, the real
numbers, the rationals, the integers, or Z_p. (A "root" is the name
for a "zero" of a polynomial function.) The package takes advantage of
other root-finding packages for polynomials within Julia (e.g.,
`PolynomialRoots` for numeric solutions over the complex numbers and
`PolynomialFactors` for exact solutions over the rationals and integers).

The basic interface is

```
poly_roots(f, domain)
```

The polynomial, `f`, is specified through a function, a vector of
coefficients (`[p0, p1, ..., pn]`), or as a `Poly{T}` object, from the
the `Polynomials.jl` package. The domain is specified by `Over.C` (the
default), `Over.R`, `Over.Q`, `Over.Z`, or `over.Zp{p}`, with variants
for specifying an underlying type.


Examples:

```
julia> poly_roots(x -> x^4 - 1, Over.C)  # uses `roots` from `PolynomialRoots.jl`
4-element Array{Complex{Float64},1}:
  0.0+1.0im
  1.0-0.0im
  0.0-1.0im
 -1.0+0.0im


julia> poly_roots(x -> x^4 - 1, Over.R)
2-element Array{Float64,1}:
  1.0
  -1.0

julia> poly_roots(x -> x^4 - 1, Over.Q) # uses `PolynomialFactors.jl`
2-element Array{Rational{Int64},1}:
 -1//1
  1//1

julia> poly_roots(x -> x^4 - 1, Over.Z) # uses `PolynomialFactors.jl`
2-element Array{Int64,1}:
 -1
  1

julia> poly_roots(x -> x^4 - 1, Over.Zp{5}) # uses `PolynomialFactors.jl`
4-element Array{Int64,1}:
 4
 1
 3
 2
```

Domains can also have their underlying types specified. For example, to solve
over the `BigFloat` type, we have:

```julia
poly_roots(x -> x^4 - 1, Over.CC{BigFloat})  # `CC{BigFloat}` not just `C`
using DoubleFloats  # significantly faster than BigFloat
poly_roots(x -> x^4 - 1, Over.CC{Double64})
4-element Array{Complex{DoubleFloat{Float64}},1}:
                    1.0 + 0.0im
                   -1.0 + 0.0im
 -7.851872429582108e-35 - 1.0im
 -7.851872429582108e-35 + 1.0im
```

There are other methods for `Over.C`. This will use the AMVW method:

```
julia> poly_roots(x -> x^4 - 1, Over.C, method=:amvw) # might differ slightly
4-element Array{Complex{Float64},1}:
 -2.1603591655723396e-16 - 0.9999999999999999im
 -2.1603591655723396e-16 + 0.9999999999999999im
                     1.0 + 0.0im
                    -1.0 + 0.0im
```

This method is useful for high-degree polynomials (cf. [FastPolynomialRoots](https://github.com/andreasnoack/FastPolynomialRoots.jl)):


```
n = 5000
rs = poly_roots(randn(n+1))
sum(isreal, rs) # 0
sum(!isnan, rs) # 1 (should be n)
rs = poly_roots(randn(n+1), method=:amvw)
sum(isreal, rs)  # 6 ~  6.04... = 2/π*log(n) + 0.6257358072 + 2/(n*π)
sum(!isnan, rs) # 5000 = n
```



## Details


This package uses:

* The `PolynomialRoots` package to find roots over the complex
numbers. The `Roots` package can also be used. As well, an
implementation of the
[AMVW](http://epubs.siam.org/doi/abs/10.1137/140983434) algorithm can
be used. The default seems to be faster and as accurate as the others,
but for very high degree polynomials, the `:amvw` method should be
used, as it will be faster and more reliable.

* The `PolynomialFactors` package to return roots over the
rationals, integers, and integers modulo a prime.

* As well, it provides an algorithm to find the real
roots of polynomials.


The main motivation for this package was to move the polynomial
specific code out of the `Roots` package. This makes the `Roots`
package have fewer dependencies and a more focused task. In addition,
the polynomial specific code could use some better implementations of
the underlying algorithms.

In the process of doing this, making a common interface to the other
root-finding packages seemed to make sense.

### Other possibly useful methods

The package also provides

* `PolynomialZeros.AGCD.agcd` for computing an *approximate* GCD of
  polynomials `p` and `q` over `Poly{Float64}`. (This is used to
  reduce a polynomial over the reals to a square-free
  polynomial. Square-free polynomials are needed for the
  algorithm used. This algorithm can become unreliable for degree 15
  or more polynomials.)

* `PolynomialZeros.MultRoot.multroot` for finding roots of `p` in
  `Poly{Float64}` over `Complex{Float64}` which has some advantage if
  `p` has high multiplicities. The `roots` function from the
  `Polynomials` package will find all the roots of a polynomial. Its
  performance degrades when the polynomial has high
  multiplicities. The `multroot` function is provided to handle this
  case a bit better. The function follows algorithms due to Zeng,
  "Computing multiple roots of inexact polynomials", Math. Comp. 74
  (2005), 869-903.

```
x = variable(Float64)
p = (x-1)^4 * (x-2)^3 * (x-3)^2 * (x-4)
q = polyder(p)
gcd(p,q) # should be (x-1)^3 * (x-2)^2 * (x-3), but is a constant
u,v,w,resid = PolynomialZeros.AGCD.agcd(p,q)
LinearAlgebra.norm(u - (x-1)^3*(x-2)^2*(x-3), Inf)  ~ 3.8e-6
```

```
poly_roots(p) # 2 real, 8 complex
PolynomialZeros.MultRoot.multroot(p) # ([4.0,3.0,2.0,1.0], [1, 2, 3, 4])
```
