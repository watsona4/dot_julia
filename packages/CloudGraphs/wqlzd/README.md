![GitHub Logo](/logo.png)

# CloudGraphs.jl

[![Build Status][build-img]][build-url]
[![CloudGraphs][cg-badge-v0.7]][cg-pkg-v0.7]
[![CloudGraphs][cg-badge-v1.0]][cg-pkg-v1.0]
[![codecov.io][cov-img]][cov-url]

Repository for the CloudGraphs project, an ongoing project on http://semisortedblog.wordpress.com.

## Installation

This package is written for the [Julia language](http://www.julialang.org) (and [JuliaPro](http://www.juliacomputing.com)), and can be cloned via:

```julia
Pkg.clone("https://github.com/GearsAD/CloudGraphs.jl.git")
```
We are in the process of registering the package for easier install.

Please note that this package requires MongoDB version `3` or higher for local DB usage.

## Users

This package is extensively used by the [Caesar.jl](http://www.github.com/dehann/Caesar.jl) package.

## Contributors

- GearsAD
- Dehann

# References

    [1]  Fourie, D., Claassens, S., Pillai, S., Mata, R., Leonard, J.: "SLAMinDB: Centralized graph
         databases for mobile robotics" IEEE International Conference on Robotics and Automation (ICRA),
         Singapore, 2017.


[cov-img]: https://codecov.io/github/GearsAD/CloudGraphs.jl/coverage.svg?branch=master
[cov-url]: https://codecov.io/github/GearsAD/CloudGraphs.jl?branch=master
[build-img]: https://travis-ci.org/GearsAD/CloudGraphs.jl.svg?branch=master
[build-url]: https://travis-ci.org/GearsAD/CloudGraphs.jl

[cg-badge-v0.7]: http://pkg.julialang.org/badges/CloudGraphs_0.7.svg
[cg-pkg-v0.7]: http://pkg.julialang.org/?pkg=CloudGraphs&ver=0.7
[cg-badge-v1.0]: http://pkg.julialang.org/badges/CloudGraphs_1.0.svg
[cg-pkg-v1.0]: http://pkg.julialang.org/?pkg=CloudGraphs&ver=1.0
