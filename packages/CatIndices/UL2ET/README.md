# CatIndices

[![Build Status](https://travis-ci.org/JuliaArrays/CatIndices.jl.svg?branch=master)](https://travis-ci.org/JuliaArrays/CatIndices.jl)

[![codecov.io](http://codecov.io/github/JuliaArrays/CatIndices.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaArrays/CatIndices.jl?branch=master)

A Julia package for concatenating, growing, and shrinking arrays in
ways that allow control over the resulting axes.

# Usage

## BidirectionalVector

These vectors can grow or shrink from either end, and the axes
update correspondingly. In this demo, pay careful attention to the
axes at each step:

```julia
julia> using CatIndices

julia> v = BidirectionalVector(rand(3))
CatIndices.BidirectionalVector{Float64} with indices CatIndices.URange(1,3):
 0.32572
 0.250426
 0.834728

julia> append!(v, rand(2))
CatIndices.BidirectionalVector{Float64} with indices CatIndices.URange(1,5):
 0.32572
 0.250426
 0.834728
 0.388788
 0.282573

julia> prepend!(v, rand(3))
CatIndices.BidirectionalVector{Float64} with indices CatIndices.URange(-2,5):
 0.992902
 0.849368
 0.189849
 0.32572
 0.250426
 0.834728
 0.388788
 0.282573

julia> pop!(v)
0.28257294456774673

julia> axes(v)
(CatIndices.URange(-2,4),)

julia> popfirst!(v)
0.9929020233076613

julia> axes(v)
(CatIndices.URange(-1,4),)
```

`deleteat!` and `insert!` are not supported, since it is unclear
whether it should shrink/grow from the beginning or end.  To eliminate
many items at the beginning or end of the vector, this package exports
`deletehead!(v, n)` and `deletetail!(v, n)`.

# Concatenation

TODO
