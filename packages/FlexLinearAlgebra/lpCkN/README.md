# FlexLinearAlgebra

[![Build Status](https://travis-ci.org/scheinerman/FlexLinearAlgebra.jl.svg?branch=master)](https://travis-ci.org/scheinerman/FlexLinearAlgebra.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/FlexLinearAlgebra.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/FlexLinearAlgebra.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/FlexLinearAlgebra.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/FlexLinearAlgebra.jl?branch=master)

A typical vector is indexed by integers 1, 2, 3, ..., n. The goal of this package
is to create vectors (and eventually matrices) with arbitrary index sets.

## The `FlexVector`

A `FlexVector` behaves much like a linear algebra vector, but the index set
can be arbitrary. A new, all zero-valued vector is created by calling
`FlexVector(dom)` where `dom` is the index set. This can be any iterable
Julia object (such as an `Array`, `Set`, etc.). By default, the zero values
in this vector are of type `Float64`, but one can also invoke `FlexVector{Int}(dom)`
and the resulting vector's values are `Int`s.
```julia
julia> using FlexLinearAlgebra

julia> v = FlexVector(4:7)
FlexVector{Int64,Float64}:
  4 => 0.0
  5 => 0.0
  6 => 0.0
  7 => 0.0

julia> w = FlexVector{Int}([1,3,5])
FlexVector{Int64,Int64}:
  1 => 0
  3 => 0
  5 => 0

julia> dom = ["alpha", "bravo", "charlie"]
3-element Array{String,1}:
 "alpha"  
 "bravo"  
 "charlie"

julia> FlexVector{Complex}(dom)
FlexVector{String,Complex}:
  alpha => 0 + 0im
  bravo => 0 + 0im
  charlie => 0 + 0im
```

### Additional constructors

The function `FlexOnes` can be used to generate a vector of all ones. Use
either `FlexOnes(dom)` or `FlexOnes(T,dom)` like this:
```julia
julia> FlexOnes(3:5)
FlexVector{Int64,Float64}:
  3 => 1.0
  4 => 1.0
  5 => 1.0

julia> FlexOnes(Complex,3:5)
FlexVector{Int64,Complex}:
  3 => 1 + 0im
  4 => 1 + 0im
  5 => 1 + 0im
```

The function `FlexConvert` converts an ordinary `Vector` into a
`FlexVector`. The index set for the result is  `1,2,...,n`
where `n` is the length of the vector.
```julia
julia> FlexConvert([1-2im,2+3im])
FlexVector{Int64,Complex{Int64}}:
  1 => 1 - 2im
  2 => 2 + 3im
```

### Accessing elements of a `FlexVector`

The values held in a `FlexVector` may be accessed and modified using the usual
Julia square-bracket notation:
```julia
julia> v[4]=7
7

julia> v
FlexVector{Int64,Float64}:
  4 => 7.0
  5 => 0.0
  6 => 0.0
  7 => 0.0
```
The indices for a `FlexVector` `v` can be recovered using `keys(v)`.

To delete an entry from a `FlexVector` use `delete_entry!(v,k)` where
`k` is the index of the entry to be deleted. 


**Note**: It is not an error to access a key that is undefined for a given
vector. Even if `k` is not a key, one may assign to `v[k]`, in which case
the vector is modified to include that value. One may also look up the value
`v[k]` in which case zero is returned and the vector is *not* modified.

### Convert to a Julia `Vector`

If `v` is a `FlexVector`, then `Vector(v)` converts `v` into a Julia
vector. The keys are lost and we simply have the values of `v` placed
into a one-dimensional array.

## Vector arithmetic

Vector addition/subtraction and scalar multiplication are supported.
If the domains of the two vectors are not the same, the resulting vector's
domain is the union of the two domains. For example:
```julia
julia> v = FlexOnes(Complex{Int},1:4)
FlexVector{Int64,Complex{Int64}}:
  1 => 1 + 0im
  2 => 1 + 0im
  3 => 1 + 0im
  4 => 1 + 0im

julia> w = FlexOnes(3:6)
FlexVector{Int64,Float64}:
  3 => 1.0
  4 => 1.0
  5 => 1.0
  6 => 1.0

julia> v+w
FlexVector{Int64,Complex{Float64}}:
  1 => 1.0 + 0.0im
  2 => 1.0 + 0.0im
  3 => 2.0 + 0.0im
  4 => 2.0 + 0.0im
  5 => 1.0 + 0.0im
  6 => 1.0 + 0.0im
```
Notice that the two domains overlap at keys 2 and 3, so the result of the
addition at those values is `2.0 + 0.0im`. At other keys, there's a tacit zero value
taken from the vector that does not have that key.

The sum of the entries in a vector can be computed with `sum(v)`. The
dot product of two vectors is computed with `dot`. If `v` contains
complex values, then `dot(v,w)` conjugates the values in `v`.
```julia
julia> v
FlexVector{Int64,Float64}:
  1 => 2.0
  2 => 4.0

julia> w
FlexVector{Int64,Float64}:
  1 => 3.0
  2 => 5.0

julia> dot(v,w)
26.0

julia> v = FlexConvert([1-2im,2+3im])
FlexVector{Int64,Complex{Int64}}:
  1 => 1 - 2im
  2 => 2 + 3im

julia> w = FlexConvert([-3im,5+2im])
FlexVector{Int64,Complex{Int64}}:
  1 => 0 - 3im
  2 => 5 + 2im

julia> dot(v,w)
22 - 14im

julia> dot(w,v)
22 + 14im
```

## The `FlexMatrix`

A `FlexMatrix` is the 2-dimensional analogue of a `FlexVector`. Important
functions include:
+ Arithmetic: Addition, subtraction, and multiplication (scalar, matrix-matrix,
  and matrix-vector).
+ Indexing: Usual `A[i,j]` notation. Also see `row_keys` and `col_keys`
  to get a list for the row/column names.
+ `FlexConvert` to convert a Julia matrix into a `FlexMatrix`.
+ `Matrix(A)` to convert a `FlexMatrix` `A` into a Julia matrix.
+ `delete_row!(A,r)` and `delete_col!(A,c)` are used to delete the line of
  `A` specified.

Note that assigning to a matrix `A[i,j]=x` will not fail. The set of row and
column names will simply be expanded and extra slots filled with zeros.

<hr>

Can't seem to get `.*` multiplication working.
