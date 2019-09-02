# LRSLib

| **PackageEvaluator** | **Build Status** | **References to cite** |
|:--------------------:|:----------------:|:----------------------:|
| [![][pkg-0.6-img]][pkg-0.6-url] | [![Build Status][build-img]][build-url] | [![DOI][zenodo-img]][zenodo-url] |
| [![][pkg-0.7-img]][pkg-0.7-url] | [![Coveralls branch][coveralls-img]][coveralls-url] [![Codecov branch][codecov-img]][codecov-url] | |

LRSLib.jl is a wrapper for [lrs](http://cgm.cs.mcgill.ca/~avis/C/lrs.html). This module can either be used in a "lower level" using the [API of lrslib](http://cgm.cs.mcgill.ca/~avis/C/lrslib/lrslib.html) or using the higher level interface of [Polyhedra.jl](https://github.com/JuliaPolyhedra/Polyhedra.jl).

As written in the [user guide of lrs](http://cgm.cs.mcgill.ca/~avis/C/lrslib/USERGUIDE.html#Introduction):
> A polyhedron can be described by a list of inequalities (H-representation) or as by a list of its vertices and extreme rays (V-representation). lrs is a C program that converts a H-representation of a polyhedron to its V-representation, and vice versa.  These problems are known respectively at the vertex enumeration and convex hull problems.

I have [forked lrs](https://github.com/blegat/lrslib) to add a few functions to help doing the wrapper.
These changes are not upstream yet so this version is used instead of the upstream version.

**Important notice**: Windows is not supported yet.

[pkg-0.6-img]: http://pkg.julialang.org/badges/LRSLib_0.6.svg
[pkg-0.6-url]: http://pkg.julialang.org/?pkg=LRSLib
[pkg-0.7-img]: http://pkg.julialang.org/badges/LRSLib_0.7.svg
[pkg-0.7-url]: http://pkg.julialang.org/?pkg=LRSLib

[build-img]: https://travis-ci.org/JuliaPolyhedra/LRSLib.jl.svg?branch=master
[build-url]: https://travis-ci.org/JuliaPolyhedra/LRSLib.jl
[coveralls-img]: https://coveralls.io/repos/github/JuliaPolyhedra/LRSLib.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/JuliaPolyhedra/LRSLib.jl?branch=master
[codecov-img]: http://codecov.io/github/JuliaPolyhedra/LRSLib.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaPolyhedra/LRSLib.jl?branch=master

[zenodo-url]: https://doi.org/10.5281/zenodo.1214579
[zenodo-img]: https://zenodo.org/badge/DOI/10.5281/zenodo.1214579.svg
