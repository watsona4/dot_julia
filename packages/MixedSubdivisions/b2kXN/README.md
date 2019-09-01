# MixedSubdivisions.jl

| **Documentation** | **Build Status** |
|:-----------------:|:----------------:|
| [![][docs-stable-img]][docs-stable-url] | [![Build Status][build-img]][build-url] |
| [![][docs-latest-img]][docs-latest-url] | [![Codecov branch][codecov-img]][codecov-url] |


A Julia package for computing a (fine) mixed subdivision and the [mixed volume](https://en.wikipedia.org/wiki/Mixed_volume) of lattice polytopes.
The mixed volume of lattice polytopes arising as Newton polytopes of a polynomial system
gives an upper bound of the number of solutions of the system. This is the celebrated
[BKK-Theorem](https://en.wikipedia.org/wiki/Bernstein–Kushnirenko_theorem).
A (fine) mixed subdivision can be used to efficiently solve sparse polynomial systems as
first described in [A Polyhedral Method for Solving Sparse Polynomial Systems](https://www.jstor.org/stable/2153370)
by Huber and Sturmfels.

There are many algorithms for computing mixed volumes and mixed subdivisions. This implementation
is based on the tropical homotopy continuation algorithm by Anders Jensen described in [arXiv:1601.02818](https://arxiv.org/abs/1601.02818).

## Installation

The package can be installed via the Julia package manager
```julia
pkg> add MixedSubdivisions
```


[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-stable-url]: https://saschatimme.github.io/MixedSubdivisions.jl/stable
[docs-latest-url]: https://saschatimme.github.io/MixedSubdivisions.jl/latest

[build-img]: https://travis-ci.org/saschatimme/MixedSubdivisions.jl.svg?branch=master
[build-url]: https://travis-ci.org/saschatimme/MixedSubdivisions.jl
[codecov-img]: https://codecov.io/gh/saschatimme/MixedSubdivisions.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/saschatimme/MixedSubdivisions.jl
