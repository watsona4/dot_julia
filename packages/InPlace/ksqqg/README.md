# InPlace.jl - in-place operations where possible

| **Build Status**                                                | **Test coverage**                                       |
|:---------------------------------------------------------------:|:-------------------------------------------------------:|
| [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] | [![Coverage Status][codecov-img]][codecov-url]      |

## Synopsis

```julia
using InPlace
a = big"1"
b = a
@inplace b += 2
a   # is now also equal to 3
```

## Description

This package exposes a single macro, `@inplace`, which applies the operation
in its expression argument in-place on the left-hand side (if it is mutable).

Examples:

```julia
@inplace a = f(args...)
@inplace a += expr
```

In the case where `a` is mutable, it is an implementation detail whether its
value is actually modified. For this reason, one should use this operation
only on values for which the current stackframe holds the only reference; e.g.
by using `deepcopy`.

In this version of the package, it is only the `+`,`-` (unary and binary) and
`*` operations that are done in-place, and only for `BigInt` operands.

## References

This package was created for speeding up [`PolynomialRings.jl`][poly].

[poly]: https://github.com/tkluck/PolynomialRings.jl

[travis-img]: https://travis-ci.org/tkluck/InPlace.jl.svg?branch=master
[travis-url]: https://travis-ci.org/tkluck/InPlace.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/4g6ax1ni7ijx3rn4?svg=true
[appveyor-url]: https://ci.appveyor.com/project/tkluck/inplace-jl

[codecov-img]: https://codecov.io/gh/tkluck/InPlace.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/tkluck/InPlace.jl
