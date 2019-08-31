# CRlibm.jl

[![Build Status](https://travis-ci.org/JuliaIntervals/CRlibm.jl.svg?branch=master)](https://travis-ci.org/dpsanders/CRlibm.jl)

A Julia wrapper around the [`CRlibm` library](http://lipforge.ens-lyon.fr/www/crlibm/). This library provides Correctly-Rounded mathematical functions, as described on the
library's home page:


> ### `CRlibm`, an efficient and proven correctly-rounded mathematical library

> `CRlibm` is a free mathematical library (libm) which provides:

> - implementations of the double-precision C99 standard elementary functions,
> - correctly rounded in the four IEEE-754 rounding modes,
> - with a comprehensive proof of both the algorithms used and their implementation,
> - sufficiently efficient in average time, worst-case time, and memory consumption to replace existing libms transparently,

> `CRlibm` is distributed under the GNU Lesser General Public License (LGPL).

This Julia wrapper is distributed under the MIT license.

## Usage

```julia
using CRlibm
```

The floating-point rounding mode must be set to `RoundNearest` for
the library to work correctly;
normally nothing needs to be done, since this is the default value:
```julia
julia> rounding(Float64)
RoundingMode{:Nearest}()
```

The library provides correctly-rounded versions of elementary functions such as
`sin`, and  `exp` (see [below](#list-of-implemented-functions) for a complete list). They are used as follows:


```julia
julia> CRlibm.cos(0.5, RoundUp)
0.8775825618903728

julia> CRlibm.cos(0.5, RoundDown)
0.8775825618903726

julia> CRlibm.cos(0.5, RoundNearest)
0.8775825618903728

julia> cos(0.5)  # built-in
0.8775825618903728

julia> CRlibm.cos(1.6, RoundToZero)
-0.029199522301288812

julia> CRlibm.cos(1.6, RoundDown)
-0.029199522301288815

julia> CRlibm.cos(0.5)  # equivalent to `CRlibm.cos(0.5, RoundNearest)`
0.8775825618903728
```
Note that the functions are not exported, so the `CRlibm.` is necessary.

## List of implemented functions

All functions from `CRlibm` are wrapped, except the power function:
- `exp`, `expm1`
- `log`, `log1p`, `log2`, `log10`
- `sin`, `cos`, `tan`
- `asin`, `acos`, `atan`
- `sinh`, `cosh`
- `sinpi`, `cospi`
- `tanpi`, `atanpi`

Since v0.5 of `CRlibm`, **no functions are exported**.

The available rounding modes are `RoundNearest`, `RoundUp`, `RoundDown` and
`RoundToZero`.


## What is correct rounding?
Suppose that we ask Julia to calculate the cosine of a number:
```julia
julia> cos(0.5)
0.8775825618903728
```
using the [built-in mathematics library, OpenLibm](https://github.com/JuliaLang/openlibm).
The result is a floating-point number that is a very good approximation to the
true value. However, we do not know if the result that Julia gives is below or
above the true value, nor how far away it is.

Correctly-rounded functions **guarantee** that when the result is not
exactly representable as a floating-point number, the value returned is *the next
largest* floating-point number, when rounding up, or *the next smallest* when
rounding down. This is equivalent to doing the calculation in infinite
precision and *then* performing the rounding.

## Rationale for the Julia wrapper

The `CRlibm` library is state-of-the-art as regards correctly-rounded
functions of `Float64` arguments. It is required for our interval arithmetic library,
[`ValidatedNumerics`](https://github.com/dpsanders/ValidatedNumerics.jl).
Having gone to the trouble of wrapping it, it made sense to release it separately;
for example, it could be used to test the quality of the `OpenLibm` functions.

## Lacunae

`CRlibm` is missing a (guaranteed) correctly-rounded power function (`x^y`), since the fact
that there are two arguments, instead of a single argument for functions such
as `sin`, means that correct rounding is *much* harder; see e.g. reference [1]  [here](http://perso.ens-lyon.fr/jean-michel.muller/p1-Kornerup.pdf).

[1] P. Kornerup, C. Lauter, V. Lefèvre, N. Louvet and J.-M. Muller
Computing Correctly Rounded Integer Powers in Floating-Point Arithmetic
ACM Transactions on Mathematical Software **37**(1), 2010

## `MPFR` as an alternative to `CRlibm`

As far as we are aware, the only alternative package to `CRlibm` is [`MPFR`](http://www.mpfr.org/). This provides correctly-rounded functions for
floating-point numbers of **arbitrary precision**, *including* the power function. However, it can be slow.

MPFR is wrapped in base Julia in the `BigFloat` type. It can emulate double-precision floating point by setting the precision to 53 bits, and using `setrounding`:

```julia
julia> setprecision(53)
53

julia> b = setrounding(BigFloat, RoundDown) do
           a = parse(BigFloat, "2.1")
           a^3
       end
9.2609999999999939

julia> c = setrounding(BigFloat, RoundUp) do
           a = parse(BigFloat, "2.1")
           a^3
       end
9.2610000000000028

```

## Wrapping MPFR (`BigFloat`)

MPFR (`BigFloat`) functions are extended with the same syntax with explicit rounding modes:
```julia
julia> setprecision(64)
64

julia> CRlibm.exp(BigFloat(0.51), RoundDown)
1.66529119494588632316

julia> CRlibm.exp(BigFloat(0.51), RoundUp)
1.66529119494588632327
```


The function `CRlibm.shadow_MPFR()` can be called to redefine the functions that take floating-point arguments to also use the MPFR versions; this is automatic if the `CRlibm` library is not available.


## Author
- [David P. Sanders](http://sistemas.fciencias.unam.mx/~dsanders),
Departamento de Física, Facultad de Ciencias, Universidad Nacional Autónoma de México (UNAM)

## Acknowledgements ##
Financial support is acknowledged from DGAPA-UNAM PAPIME grant PE-107114 and DGAPA-UNAM PAPIIT grant IN-117214.
