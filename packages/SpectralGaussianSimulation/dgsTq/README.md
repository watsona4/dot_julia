# SpectralGaussianSimulation.jl

[![][travis-img]][travis-url] [![][codecov-img]][codecov-url]

This package provides an implementation of spectral Gaussian simulation
as described in [Gutjahr 1997](https://link.springer.com/article/10.1007/BF02769641).
In this method, the covariance function is perturbed in the frequency
domain after a fast Fourier transform. White noise is added to the phase
of the spectrum, and a realization is produced by an inverse Fourier transform.

The method is limited to simulations on regular grids, and care must be taken
to make sure that the correlation length is small enough compared to the grid
size. As a general rule of thumb, avoid correlation lengths greater than 1/3
of the grid. The method is extremely fast, and can be used to generate large
3D realizations.

## Installation

Get the latest stable release with Julia's package manager:

```julia
] add SpectralGaussianSimulation
```

## Usage

This package is part of the [GeoStats.jl](https://github.com/juliohm/GeoStats.jl) framework.

For a simple example of usage, please check [this notebook](https://nbviewer.jupyter.org/github/juliohm/SpectralGaussianSimulation.jl/blob/master/docs/Usage.ipynb).

## Asking for help

If you have any questions, please [open an issue](https://github.com/juliohm/SpectralGaussianSimulation.jl/issues).

[travis-img]: https://travis-ci.org/juliohm/SpectralGaussianSimulation.jl.svg?branch=master
[travis-url]: https://travis-ci.org/juliohm/SpectralGaussianSimulation.jl

[codecov-img]: https://codecov.io/gh/juliohm/SpectralGaussianSimulation.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/juliohm/SpectralGaussianSimulation.jl
