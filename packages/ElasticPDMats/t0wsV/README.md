# ElasticPDMats

Efficient growing and shrinking of positive definite matrices thanks to
preallocated memory.

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.org/jbrea/ElasticPDMats.jl.svg?branch=master)](https://travis-ci.org/jbrea/ElasticPDMats.jl)
[![codecov.io](http://codecov.io/github/jbrea/ElasticPDMats.jl/coverage.svg?branch=master)](http://codecov.io/github/jbrea/ElasticPDMats.jl?branch=master)

## Usage

In addition to the functions defined in the [common PDMats
interface](https://github.com/JuliaStats/PDMats.jl#common-interface),
`ElasticPDMat <: AbstractPDMat` can grow with `append!`
```julia
a = rand(10, 10); m = a'a; 
e = ElasticPDMat(m[1:8, 1:8))
append!(e, m[:, 9:10])
```
and shrink with `deleteat!`
```julia
deleteat!(e, [3, 8, 7])
```

Growing and shrinking is usually efficient, because no entries are recomputed
and (basically no) new memory needs to be allocated.  `ElasticMat(capacity =
10^3, stepsize = 10^3)` allocates `capacity x capacity` matrices and creates
(initially `0`-dimensional) views to represent positive definite matrices.
Whenever the current `capacity` is reached, e.g. due to several `append!`
operations, the `capacity` increases to `capacity += stepsize`. *Caution:*
increasing the `capacity` involves allocating new memory and copying old values,
which is slow. For optimal performance, the `capacity` and the `stepsize` should
be chosen wisely. For an already initialized `e = ElasticPDMat()` they can be
set with the helper functions `setcapacity!(e, 100)` and `setstepsize!(e, 100)`.

Additionally to `ElasticPDMat` this package exports view based elastic arrays of
any dimension `AllElasticArray`, `ElasticSymmetricMatrix`, `ElasticCholesky` and
the helper functions `setcapacity!`, `setstepsize!` and `setdimension!`.


