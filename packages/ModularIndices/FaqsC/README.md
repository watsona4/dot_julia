# ModularIndices

[![Build Status](https://travis-ci.com/ericphanson/ModularIndices.jl.svg?branch=master)](https://travis-ci.com/ericphanson/ModularIndices.jl)
[![Codecov](https://codecov.io/gh/ericphanson/ModularIndices.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ericphanson/ModularIndices.jl)

A very simple package (26 lines of code before comments, docstring, and tests) with one export: `Mod`. This is an object using for indexing, like `Colon` from Base, and `Not` from [InvertedIndices.jl](https://github.com/mbauman/InvertedIndices.jl). `Mod` provides an easy way to have wrap-around indexing of vectors and arrays (which can otherwise be annoying with 1-based indexing).

Usage:
```julia
julia> A = rand(3)
3-element Array{Float64,1}:
 0.523471984061487
 0.3975791533002422
 0.3230510641200286

julia> A[Mod(4)]
0.523471984061487

julia> A[4]
ERROR: BoundsError: attempt to access 3-element Array{Float64,1} at index [4]
Stacktrace:
 [1] getindex(::Array{Float64,1}, ::Int64) at ./array.jl:729
 [2] top-level scope at none:0
```


Just like regular indexing, `Mod` accepts

* scalars like`A[Mod(1)]` (i.e. type `Int`),
* ranges like `A[Mod(1:2)]` (`AbstractRange{Int}`)
* and vectors like `A[Mod([1,2])]`  (`AbstractVector{Int}`). A non-allocating alternative is also provided here, namely `A[Mod(1,2)] == A[Mod([1,2])]`.

and is able to index into collections `A` which are indexable and use `Base.to_indices` to process the indices (which I think mostly are `AbstractArray`'s). For example, `A` could be an `Array`, `OffsetArray`, `SubArray`, `StaticArray`, etc.

This package should possibly be called `PeriodicIndices.jl` and `Mod` renamed to `Periodic` or similar.

This is similar to [FFTViews.jl](https://github.com/JuliaArrays/FFTViews.jl), but instead of constructing a periodic view type into an array, it provides an indexing object.

The code is heavily inspired by InvertedIndices.jl (but it's actually much simpler to do modular indexing than inverted indexing), and the idea for `Mod` was discussed on <https://github.com/JuliaLang/julia/issues/32571>.


## Examples

```julia
julia> A = 1:3
1:3

julia> A[Mod(4)]
1

julia> A[Mod(2:4)]
3-element Array{Int64,1}:
 2
 3
 1

julia> A = reshape(1:8, 2, 4)
2×4 reshape(::UnitRange{Int64}, 2, 4) with eltype Int64:
 1  3  5  7
 2  4  6  8

julia> A[Mod(4),2]
 4
```

Works with [OffsetArrays.jl](https://github.com/JuliaArrays/OffsetArrays.jl) too:

```julia
julia> using OffsetArrays

julia> A = OffsetArray([1,2,3], -1)
OffsetArray(::Array{Int64,1}, 0:2) with eltype Int64 with indices 0:2:
 1
 2
 3

julia> A[3]
ERROR: BoundsError: attempt to access OffsetArray(::Array{Int64,1}, 0:2) with eltype Int64 with indices 0:2 at index [3]
Stacktrace:
 [1] throw_boundserror(::OffsetArray{Int64,1,Array{Int64,1}}, ::Tuple{Int64}) at ./abstractarray.jl:484
 [2] checkbounds at ./abstractarray.jl:449 [inlined]
 [3] getindex(::OffsetArray{Int64,1,Array{Int64,1}}, ::Int64) at /Users/eh540/.julia/packages/OffsetArrays/vIbpP/src/OffsetArrays.jl:135
 [4] top-level scope at none:0

julia> A[Mod(3)]
1

```
