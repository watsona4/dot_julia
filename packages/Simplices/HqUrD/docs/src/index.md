# Simplices.jl documentation

Julia package for computing exact intersection volumes between n-dimensional simplices.

## Release info
Version 0.6.2 of the package is preliminary and only works for
Julia 0.6. Volume computations have been tested for up to dimension 10, but the code is messy. A cleaned up version will be released for Julia 1.0.

## Usage
Simplex intersections are computed by calling [`simplexintersection`](@ref) with the simplices in question. The simplices must be arrays of size `(dim, dim + 1)`, so that each vertex of the simplex is a column vector.

[Simplex properties](@ref) can also be computed for individual simplices. There are also some  functions that can be used to generate pairs of simplices that overlap in certain ways, or points that lie either outside or inside a simplex ([Generation of (non)intersecting simplices/points](@ref)).

### 3D example

```@repl
using Simplices
s₁, s₂ = rand(3, 4), rand(3, 4)
simplexintersection(s₁, s₂)
```

### 5D example

```@repl
using Simplices
s₃, s₄ = rand(4, 5), rand(4, 5)
simplexintersection(s₃, s₄)
```
