# StandardizedMatrices

[![Build Status](https://travis-ci.org/joshday/StandardizedMatrices.jl.svg?branch=master)](https://travis-ci.org/joshday/StandardizedMatrices.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/xmouaoa7xal6n4gq?svg=true)](https://ci.appveyor.com/project/joshday/standardizedmatrices-jl)
[![codecov](https://codecov.io/gh/joshday/StandardizedMatrices.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/StandardizedMatrices.jl)



Statisticians often work with standardized matrices.  If `x` is a data matrix with observations in rows, we want to work with `z = StatsBase.zscore(x, 1)`.  This package defines a `StandardizedMatrix` type that treats a matrix as standardized without copying or changing data in place.

# A Motivating Example

Suppose our original matrix is sparse and we want to perform matrix-vector multiplication with a standardized version.  Typically, standardizing a sparse matrix destroys the sparsity.

```julia
using StatsBase, BenchmarkTools, StandardizedMatrices

# generate some data
n, p = 100_000, 1000
x = sprandn(n, p, .01)
β = randn(p)

xdense = zscore(x, 1)		# this destroys the sparsity
z = StandardizedMatrix(x)	# this acts as standardized, but keeps sparse benefits

b1 = @benchmark xdense * β
b2 = @benchmark z * β
ratio(median(b1), median(b2))  # StandardizedMatrix is roughly 13 times faster
```


# Methods implemented:

- `*()`
- `mul!(Y, A::StandardizedMatrix, B)`
