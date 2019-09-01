# DirectGaussianSimulation.jl

[![][travis-img]][travis-url] [![][codecov-img]][codecov-url]

This package provides an implementation of direct Gaussian simulation (a.k.a. LU simulation)
as described in [Alabert 1987](https://link.springer.com/article/10.1007/BF00897191). In this
method, the full covariance matrix is built to include all locations of the simulation domain,
and samples from the multivariate Gaussian are drawn via LU factorization.

The method, which is widely implemented in many packages for Gaussian processes (e.g.
[GaussianProcesses.jl](https://github.com/STOR-i/GaussianProcesses.jl),
[GaussianRandomFields.jl](https://github.com/PieterjanRobbe/GaussianRandomFields.jl)),
is appropriate for relatively small simulation domains (e.g. 100x100 grids) where it is feasible
to factorize the full covariance. For larger domains (e.g. 3D grids), other methods are available
such as sequential Gaussian simulation, spectral methods, and FFT moving averages.

## Installation

Get the latest stable release with Julia's package manager:

```julia
] add DirectGaussianSimulation
```

## Usage

This package is part of the [GeoStats.jl](https://github.com/juliohm/GeoStats.jl) framework.

For a simple example of usage, please check [this notebook](https://nbviewer.jupyter.org/github/juliohm/DirectGaussianSimulation.jl/blob/master/docs/Usage.ipynb).

## Asking for help

If you have any questions, please [open an issue](https://github.com/juliohm/DirectGaussianSimulation.jl/issues).

[travis-img]: https://travis-ci.org/juliohm/DirectGaussianSimulation.jl.svg?branch=master
[travis-url]: https://travis-ci.org/juliohm/DirectGaussianSimulation.jl

[codecov-img]: https://codecov.io/gh/juliohm/DirectGaussianSimulation.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/juliohm/DirectGaussianSimulation.jl
