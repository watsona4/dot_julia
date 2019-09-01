# ProjectiveVectors.jl
| **Documentation** | **Build Status** |
|:-----------------:|:----------------:|
| [![][docs-stable-img]][docs-stable-url] | [![Build Status][build-img]][build-url] |
| [![][docs-dev-img]][docs-dev-url] | [![Codecov branch][codecov-img]][codecov-url] |

Data structure for elements in products of projective spaces. This package defines as type `PVector{T,N}` where `T` is the
element type and `N` is the number of projective spaces in which the vector lives.

```julia
julia> using ProjectiveVectors, LinearAlgebra

# We want to consider the vector [1, 2, 3, 4, 5, 6] as a vector [1:2:3]×[4:5:6] in P²×P²
julia> PVector([1, 2, 3, 4, 5, 6], (2, 2))
PVector{Int64, 2}:
 [1, 2, 3] × [4, 5, 6]

# We also can embed an affine vector into a projective space.
# Here we embed [2, 3, 4, 5, 6, 7] into P²×P³×P¹
julia> v = embed([2, 3, 4, 5, 6, 7], (2, 3, 1))
PVector{Int64, 3}:
 [2, 3, 1] × [4, 5, 6, 1] × [7, 1]

# We support several linear algebra routines. These always return a tuple
julia> norm(v)
(3.7416573867739413, 8.831760866327848, 7.0710678118654755)

julia> w = embed([2, 3, 4])
PVector{Int64, 1}:
 [2, 3, 4, 1]

julia> norm(w, Inf)
(4.0,)
```

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://www.juliahomotopycontinuation.org/ProjectiveVectors.jl/stable
[docs-dev-url]: https://www.juliahomotopycontinuation.org/ProjectiveVectors.jl/dev

[build-img]: https://travis-ci.org/JuliaHomotopyContinuation/ProjectiveVectors.jl.svg?branch=master
[build-url]: https://travis-ci.org/JuliaHomotopyContinuation/ProjectiveVectors.jl
[codecov-img]: https://codecov.io/gh/juliahomotopycontinuation/HomotopyContinuation.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/juliahomotopycontinuation/ProjectiveVectors.jl
