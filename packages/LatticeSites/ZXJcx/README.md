# LatticeSites.jl

[![Build Status](https://travis-ci.org/Roger-luo/LatticeSites.jl.svg?branch=master)](https://travis-ci.org/Roger-luo/LatticeSites.jl)

Type for different kind of sites on different lattices.

## Installation

```
pkg> add https://github.com/Roger-luo/LatticeSites.jl.git
```

## Intro

This package provides types for sites, which defines the configuration of a lattice.

Binary configuration label is provided as:

- `Bit`,  refers to `0`/`1`
- `Spin`, refers to `-1`/`+1`
- `Half`, refers to `-0.5`/`+0.5`
- `Clock`, refers to the 2D q-state clock model with `q` discrete spin values (`1:q`)
- `Potts`, refers to the standard Potts model with values `-q, ..., q`
- `Continuous`, is in development still and not ready.

`Array`, `StaticArray` and etc. (e.g `SparseArray`) is supported for store configurations.

It is simple, and you can use it like a `Number` (but it is not a `Number`)

```julia
julia> rand(Bit{Float64})
0.0

julia> rand(Bit{Float64}, 2, 2)
2×2 Array{Bit{Float64},2}:
 0.0  0.0
 0.0  0.0

julia> using StaticArrays

julia> rand(SMatrix{2, 2, Bit{Int}})
2×2 SArray{Tuple{2,2},Bit{Int64},2,4}:
0  1
0  1
```

and to support indexing, you can convert any `AbstractArray` contains sites to an integer
(as long as this integer type does not overflow).

```julia
julia> convert(Int, rand(SMatrix{2, 2, Bit{Int}}))
12
```

There is also a `HilbertSpace` iterator that help you iterate through the space.

```julia
julia> space = HilbertSpace{Bit{Int}}(2, 2)
HilbertSpace{Bit{Int64},Tuple{2,2},2,4}(Bit{Int64}[0 0; 0 0])

julia> collect(space)
16-element Array{Array{Bit{Int64},2},1}:
 [0 0; 0 0]
 [1 0; 0 0]
 [0 0; 1 0]
 [1 0; 1 0]
 [0 1; 0 0]
 [1 1; 0 0]
 [0 1; 1 0]
 [1 1; 1 0]
 [0 0; 0 1]
 [1 0; 0 1]
 [0 0; 1 1]
 [1 0; 1 1]
 [0 1; 0 1]
 [1 1; 0 1]
 [0 1; 1 1]
 [1 1; 1 1]
```

We use the convention that the first index `a[1]` take the first digit position
during the convention, which is opposite to natural notation `0b0101`, where the last
digit in bit string take the first position.

In short

`0b011` is equivalent to `Bit[1, 1, 0]`


## License

Apache License 2.0
