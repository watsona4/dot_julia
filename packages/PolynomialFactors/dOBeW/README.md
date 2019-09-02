# PolynomialFactors

A package for factoring polynomials with integer or rational coefficients over the integers.

[![PolynomialFactors](http://pkg.julialang.org/badges/PolynomialFactors_0.6.svg)](http://pkg.julialang.org/?pkg=PolynomialFactors&ver=0.6)

Linux: [![Build Status](https://travis-ci.org/jverzani/PolynomialFactors.jl.svg?branch=master)](https://travis-ci.org/jverzani/PolynomialFactors.jl)
&nbsp;
Windows: [![Build St 0.1.1atus](https://ci.appveyor.com/api/projects/status/github/jverzani/PolynomialFactors.jl?branch=master&svg=true)](https://ci.appveyor.com/project/jverzani/polynomialfactors-jl)



For polynomials over the integers or rational numbers, this package provides

* a `factor` command to factor into irreducible factors over the integers;

* a `rational_roots` function to return the rational roots;
 
* a `powermod` function to factor the polynomial over Z/pZ.

The implementation is based on the Cantor-Zassenhaus approach, as
detailed in Chapters 14 and 15 of the excellent text *Modern Computer Algebra* by von zer
Gathen and Gerhard and a paper by Beauzamy, Trevisan, and Wang.


The factoring solutions in `SymPy.jl` or `Nemo.jl` would be preferred,
in general, especially for larger problems (degree 30 or more, say) where the performance here is not good. However, this package
requires no additional external libraries. (PRs improving performance are most welcome.)


Examples:

```
julia> using AbstractAlgebra, PolynomialFactors;

julia> R, x = ZZ["x"];

julia> p = prod(x .-[1,1,3,3,3,3,5,5,5,5,5,5])
x^12-44*x^11+874*x^10-10348*x^9+81191*x^8-443800*x^7+1728556*x^6-4818680*x^5+9505375*x^4-12877500*x^3+11306250*x^2-5737500*x+1265625

julia> poly_factor(p)
Dict{AbstractAlgebra.Generic.Poly{BigInt},Int64} with 3 entries:
  x-5 => 6
  x-1 => 2
  x-3 => 4
```

As can be seen `factor` returns a dictionary whose keys are
irreducible factors of the polynomial `p` as `Polynomial` objects, the
values being their multiplicity. If the polynomial is non-monic, a
degree $0$ polynomial is there so that the original polynomial can be
recovered as the product  `prod(k^v for (k,v) in poly_factor(p))`.


Here we construct the polynomial in terms of a variable `x`:

```
julia> poly_factor((x-1)^2 * (x-3)^4 * (x-5)^6)
Dict{AbstractAlgebra.Generic.Poly{BigInt},Int64} with 3 entries:
  x-5 => 6
  x-1 => 2
  x-3 => 4
```

Factoring over the rationals is really done over the integers, The
first step is to find a common denominator for the coefficients. The
constant polynomial term reflects this.

```
julia> R, x = QQ["x"]
(Univariate Polynomial Ring in x over Rationals, x)

julia> poly_factor( (1//2 - x)^2 * (1//3 - 1//4 * x)^5 )
Dict{AbstractAlgebra.Generic.Poly{Rational{BigInt}},Int64} with 3 entries:
  2//1*x-1//1 => 2
  3//1*x-4//1 => 5
  -1//995328  => 1
```  

For some problems big integers are necessary to express the problem:

```
julia> p = prod(x .- collect(1:20))
x^20-210*x^19+20615*x^18-1256850*x^17+53327946*x^16-1672280820*x^15+40171771630*x^14-756111184500*x^13+11310276995381*x^12-135585182899530*x^11+1307535010540395*x^10-10142299865511450*x^9+63030812099294896*x^8-311333643161390640*x^7+1206647803780373360*x^6-3599979517947607200*x^5+8037811822645051776*x^4-12870931245150988800*x^3+13803759753640704000*x^2-8752948036761600000*x+2432902008176640000

julia> poly_factor(p)
Dict{AbstractAlgebra.Generic.Poly{BigInt},Int64} with 20 entries:
  x-15 => 1
  x-18 => 1
  x-17 => 1
  x-9  => 1
  x-5  => 1
  x-14 => 1
  x-7  => 1
  x-13 => 1
  x-11 => 1
  x-2  => 1
  x-12 => 1
  x-1  => 1
  x-3  => 1
  x-8  => 1
  x-10 => 1
  x-4  => 1
  x-19 => 1
  x-16 => 1
  x-6  => 1
  x-20 => 1
```

```
julia> poly_factor(x^2 - big(2)^256)
Dict{AbstractAlgebra.Generic.Poly{BigInt},Int64} with 2 entries:
  x+340282366920938463463374607431768211456 => 1
  x-340282366920938463463374607431768211456 => 1
```  


Factoring polynomials over a finite field of coefficients, `Z_p[x]` with `p` a prime, is also provided by `factormod`:

```
julia> factormod(x^4 + 1, 2)
Dict{AbstractAlgebra.Generic.Poly{AbstractAlgebra.gfelem{BigInt}},Int64} with 1 entry:
  x+1 => 4

julia> factormod(x^4 + 1, 5)
Dict{AbstractAlgebra.Generic.Poly{AbstractAlgebra.gfelem{BigInt}},Int64} with 2 entries:
  x^2+3 => 1
  x^2+2 => 1

julia> factormod(x^4 + 1, 3)
Dict{AbstractAlgebra.Generic.Poly{AbstractAlgebra.gfelem{BigInt}},Int64} with 2 entries:
  x^2+x+2   => 1
  x^2+2*x+2 => 1

julia> factormod(x^4 + 1, 7)
Dict{AbstractAlgebra.Generic.Poly{AbstractAlgebra.gfelem{BigInt}},Int64} with 2 entries:
  x^2+3*x+1 => 1
  x^2+4*x+1 => 1
```

The keys are polynomials a finite group, not over the integers.
