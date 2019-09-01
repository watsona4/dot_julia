# FastArrays

(Formerly called `FlexibleArrays`.)

[![Build Status](https://travis-ci.org/eschnett/FastArrays.jl.svg?branch=master)](https://travis-ci.org/eschnett/FastArrays.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/qrpo2bagojcmkb6h/branch/master?svg=true)](https://ci.appveyor.com/project/eschnett/fastarrays-jl/branch/master)
[![codecov.io](https://codecov.io/github/eschnett/FastArrays.jl/coverage.svg?branch=master)](https://codecov.io/github/eschnett/FastArrays.jl?branch=master)
[![Dependency Status](https://dependencyci.com/github/eschnett/FastArrays.jl/badge)](https://dependencyci.com/github/eschnett/FastArrays.jl)
[![DOI](https://zenodo.org/badge/50477681.svg)](https://zenodo.org/badge/latestdoi/50477681)

Fast multi-dimensional arrays, with arbitrary lower and upper bounds that can be fixed at compile time to improve efficiency

## Background

Sometimes you really want arrays where the lower index bound is different from 1. This is not a question of performance, but of convenience -- for example, if you have quantum numbers ranging from `0` to `k`, then adding `1` every time you index an array looks tedious. This really should be part of the type declaration.

And sometimes, you know the size of a particular array dimension ahead of time. This is now a question of efficiency -- indexing into a multi-dimensional array is significantly more efficient if the sizes of the dimensions are known ahead of time.

This is just what this package `FastArrays` provides: A way to define multi-dimensional array types where both lower and upper index bounds can be chosen freely, and which generates more efficient code if these bounds are known ahead of time.

Here is an example:
```Julia
using FastArrays

# A (10x10) fixed-size array
const Arr2d_10x10 = FastArray(1:10, 1:10)
a2 = Arr2d_10x10{Float64}(undef, :, :)

# A 3d array with lower index bounds 0
const Arr3d_lb0 = FastArray(0, 0, 0)
a3 = Arr3d_lb0{Float64}(undef, 9, 9, 9)

# A generic array, all bounds determined at creation time
const Arr4d_generic = FastArray(:, :, :, :)
a4 = Arr4d_generic{Float64}(undef, 1:10, 0:10, -1:10, 15:15)

# These can be mixed: A (2x10) array
FastArray(0:1, 1){Float64}(undef, :, 10)

# Arrays can also be empty:
FastArray(4:13, 10:9)
FastArray(:){Int}(undef, 5:0)

# The trivial 0d array type, always holding one scalar value:
FastArray(){Int}
```

Fast arrays are accessed like regular arrays, using the `[]` notation or the `getindex` and `setindex!` functions.

You will have noticed the slightly unusual notation for fast arrays. Implementation-wise, the set of all bounds that are kept fixed determine the (parameterized) type of the array; different choices for fixed array bounds correspond to different types. `FastArray` is a function that returns the respective type, creating this type if necessary.

Currently, fast arrays do not yet support resizing, reshaping, or subarrays; adding this would be straightforward.

I designed FastArrays for the two reasons above -- I needed to model quantum numbers that have a range of `0:k`, and I noticed that the C++ version of the respecived code became significantly faster when setting array sizes at compile time. In Julia, I confirmed that the generated machine code is also much simpler in this case. Of course, this provides a benefit only if array accessing is actually a bottleneck in the code.

## Manual

Each array dimension has a lower and an upper bound. Both can either be fixed or flexible. Fixed bounds are the same for all objects of this type, flexible bounds have to be chosen when the array is allocated. Julia's `Array` types correspond to `FastArray` types where all lower bounds are fixed to `1`, and all upper bounds are flexible.

Internally, the fixed bounds are represented as a tuple of either nothing or integers: `DimSpec = NTuple{2, Union{Void, Int}}`.

For each dimension, the fixed bounds are set via:
- A range `lb:ub` to define both bounds
- An integer `lb` to define the lower bound, leaving the upper bound flexible
- A colon `:` to indicate that both lower and upper bounds are flexible
Instead of the above, you can also define the fixed bounds via a tuple of type `DimSpec`.

When an array is allocated, the flexible bounds are set conversely:
- A colon `:` indicates no flexible bounds (if both bounds are fixed)
- An integer `ub` defines the upper bound (if the lower bound is fixed)
- A range `lb:ub` defines both lower and upper bounds
- A one-element integer tuple `(lb,)` defines the lower bound (if the upper bound is fixed)

Each fast array type is subtype of `AbstractFastArray{T,N}`, where `T` is the element type and `N` is the rank. This abstract is a subtype of `DenseArray{T,N}`.

### Available array functions:

- Define a fast array type:

  ```Julia
  FastArray(<dimspec>*)
  ```

  Example:

  ```Julia
  const MyArrayType = FastArray(1:2, 1, :)
  ```

- Allocate an array:

  ```Julia
  FastArray(<dimspec>*){<type>}(undef, <flexible bounds>*)
  ```

  Example:
  Create an array with bounds `(1:2, 1:10, 1:10)`:

  ```Julia
  myarray = MyArrayType{Float64}(undef, :, 10, 1:10)
  ```

- Element type:

  ```Julia
  eltype{T}(arr::FastArray(...){T})
  eltype{T}(::Type{FastArray(...){T}})
  ```

  Example:

  ```Julia
  eltype(myarray)
  eltype(MyArrayType)
  ```

- Rank (number of dimension):

  ```Julia
  ndims{T}(arr::FastArray(...){T})
  ndims{T}(::Type{FastArray(...){T}})
  ```

  Example:

  ```Julia
  ndims(myarray)
  ndims(MyArrayType)
  ```

- Array length:

  ```Julia
  length{T}(arr::FastArray(...){T})
  ```

  If all bounds are fixed, then the array length can also be obtained from the type:

  ```Julia
  length{T}(::Type{FastArray(...){T}})
  ```

  Example:

  ```Julia
  length(myarray)
  ```

- Array bounds and sizes:

  ```Julia
  lbnd{T}(arr::FastArray(...){T}, n::Int)
  ubnd{T}(arr::FastArray(...){T}, n::Int)
  size{T}(arr::FastArray(...){T}, n::Int)
  lbnd{T}(arr::FastArray(...){T})
  ubnd{T}(arr::FastArray(...){T})
  size{T}(arr::FastArray(...){T})
  ```

  Fixed bounds and sizes can also be obtained from the type:

  ```Julia
  lbnd{T,n}(::Type{FastArray(...){T}}, ::Val{n})
  ubnd{T,n}(::Type{FastArray(...){T}}, ::Val{n})
  size{T,n}(::Type{FastArray(...){T}}, ::Val{n})
  lbnd{T}(::Type{FastArray(...){T}})
  ubnd{T}(::Type{FastArray(...){T}})
  size{T}(::Type{FastArray(...){T}})
  ```

  Example:

  ```Julia
  lbnd(myarray, 3)
  ubnd(myarray, Val{1})
  size(myarray, 2)
  lbnd(myarray)
  ubnd(myarray)
  size(myarray)
  ```

- Access array elements:

  ```Julia
  getindex{T}(arr::FastArray(...){T}, i::Int, j::Int, ...)
  setindex!{T}(arr::FastArray(...){T}, val, i::Int, j::Int, ...)
  ```

  Example:

  ```Julia
  myarray[1,2,3]
  myarray[2,3,4] = 42
  ```
