# PartedArrays.jl
![Build Status](https://travis-ci.org/bjack205/PartedArrays.jl.svg?branch=master)
[![codecov](https://codecov.io/gh/bjack205/PartedArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bjack205/PartedArrays.jl)



PartedArrays was written to make it easier to work with arrays that are naturally partitioned into sub-arrays. PartedArrays keeps the memory together in one block and simply stores fixed views into the arrays rather that storing the sub-arrays as separate entities, like [BlockArrays.jl](https://github.com/JuliaArrays/BlockArrays.jl).

For example, say we have a function, `f(x,u)` with vector-valued input `x` and `u` of size `n` and `m`, respectively. The Hessian of the function, `H`, is a symmetric matrix of size `(n+m,n+m)`. It is naturally partitioned into the partial second derivatives of f: A = df/dxdx, B = df/dudu, C = df/dxdu. `H` is then equivalent to `[A C; C' B]`. However, we don't really want to break up `H` (since we may want to invert it) but may want to extract/modify particular partial derivatives, which we could do by indexing, but that can get tedious to write and even more difficult to read. PartedArrays simplifies this by making it easy to store views into the partial derivatives along with the matrix itself.

PartedArrays was written to avoid repetitive indexing and clean up complicated indexing expressions, especially when they have a regular structure. 

## Usage
A `PartedArray` is basically just a normal Julia array with a list of convenient views attached. This list of views can either be of type `Dict{Symbol,<:Any}` or a `NamedTuple`. 
```julia
using PartedArrays

# Vector
x = rand(4)
y = rand(3)
z = [x; y]
parts = (x=1:4, y=5:7)
Z = PartedArray(z, parts)
Z.x == x  # true
Z.y == y  # true

# Matrix
A = rand(4,4)
B = rand(3,3)
C = rand(4,3)
H= [A C; C' B]
parts = (xx=(1:4,1:4), xy=(1:4,5:7), yx=(5:7,1:4), yy=(5:7,5:7))
Z = PartedArray(H, parts)
Z.xx == A  # true

parts2 = Dict(:xx=>(1:4,1:4), :yy=>(5:7,5:7), :top=>(1,:))
Z2 = PartedArray(H, parts2)
Z2.top == H[1,:]  # true
```

Since `PartedArray` uses the `AbstractArray` interface, most array-like operations are preserved
```julia
Z[1:4,1:4] == A  # true
Z + Z2 == 2Z     # true

Z[1] = 10
Z.xx[1,1] == 10  # true
```

## Partitioning
For many cases, the partitioning of the array is non-overlapping and includes the whole array. It can be cumbersome to create these partitions by hand, so some convenient constructors are provided for vectors and matrices. 

```julia
part = create_partition((4,3), (:x,:u))
Z = PartedArray(z, part)
Z.x == x  # true

part2 = create_partition2((4,3), (4,3), Val((:xx,:xu,:ux,:uu)))
Z = PartedMatrix(H, part2)
Z.xx == A  # true
```
The names of the partitions need to be passed in as Value Types for type stability (still need to make this change for 1D partitioning). 
