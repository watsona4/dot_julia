# RestrictProlong

[![Build Status](https://travis-ci.org/timholy/RestrictProlong.jl.svg?branch=master)](https://travis-ci.org/timholy/RestrictProlong.jl)

[![codecov.io](http://codecov.io/github/timholy/RestrictProlong.jl/coverage.svg?branch=master)](http://codecov.io/github/timholy/RestrictProlong.jl?branch=master)

This package provides efficient multidimensional implementations of
two operators, `restrict` and `prolong`, which feature heavily in
multigrid methods. In general terms, these operations reduce and
increase, respectively, the size of arrays by a factor of 2 along one
or more dimensions.  The two operators satisfy the "Galerkin
condition," meaning that as operators they are transposes of one
another.

In addition to being useful for mulitigrid methods, `restrict` can be
used as a fast antialiasing thumbnail generator for images.

## Usage examples

Set up the following test array:

```julia
julia> using RestrictProlong

julia> A = zeros(5,5); A[3,3] = 1
1

julia> A
5×5 Array{Float64,2}:
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
```

`restrict` reduces the size along the chosen dimension(s) (all
dimensions are chosen if not specified), approximately preserving the
mean value of the input array:

```jl
julia> restrict(A)
3×3 Array{Float64,2}:
 0.0  0.0   0.0
 0.0  0.25  0.0
 0.0  0.0   0.0
```

After restriction, an axis with `l = size(A, d)` has size `(l+1) ÷ 2`.

For prolongation, it's best to specify the desired target size, which can be either `2l` or `2l-1`:
```julia
julia> prolong(A, (10,10))
10×10 Array{Float64,2}:
 0.0  0.0  0.0  0.0       0.0       0.0       0.0       0.0  0.0  0.0
 0.0  0.0  0.0  0.0       0.0       0.0       0.0       0.0  0.0  0.0
 0.0  0.0  0.0  0.0       0.0       0.0       0.0       0.0  0.0  0.0
 0.0  0.0  0.0  0.015625  0.046875  0.046875  0.015625  0.0  0.0  0.0
 0.0  0.0  0.0  0.046875  0.140625  0.140625  0.046875  0.0  0.0  0.0
 0.0  0.0  0.0  0.046875  0.140625  0.140625  0.046875  0.0  0.0  0.0
 0.0  0.0  0.0  0.015625  0.046875  0.046875  0.015625  0.0  0.0  0.0
 0.0  0.0  0.0  0.0       0.0       0.0       0.0       0.0  0.0  0.0
 0.0  0.0  0.0  0.0       0.0       0.0       0.0       0.0  0.0  0.0
 0.0  0.0  0.0  0.0       0.0       0.0       0.0       0.0  0.0  0.0

julia> prolong(A, (9,10))
9×10 Array{Float64,2}:
 0.0  0.0  0.0  0.0      0.0      0.0      0.0      0.0  0.0  0.0
 0.0  0.0  0.0  0.0      0.0      0.0      0.0      0.0  0.0  0.0
 0.0  0.0  0.0  0.0      0.0      0.0      0.0      0.0  0.0  0.0
 0.0  0.0  0.0  0.03125  0.09375  0.09375  0.03125  0.0  0.0  0.0
 0.0  0.0  0.0  0.0625   0.1875   0.1875   0.0625   0.0  0.0  0.0
 0.0  0.0  0.0  0.03125  0.09375  0.09375  0.03125  0.0  0.0  0.0
 0.0  0.0  0.0  0.0      0.0      0.0      0.0      0.0  0.0  0.0
 0.0  0.0  0.0  0.0      0.0      0.0      0.0      0.0  0.0  0.0
 0.0  0.0  0.0  0.0      0.0      0.0      0.0      0.0  0.0  0.0
```

`prolong` approximately preserves the sum of the input array.
