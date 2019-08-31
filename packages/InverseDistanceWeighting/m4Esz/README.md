# InverseDistanceWeighting.jl

[![][travis-img]][travis-url] [![][codecov-img]][codecov-url]

This package provides a high-performance implementation of the inverse distance weighting scheme introduced in
the very early days of geostatistics (see [Shepard 1968](https://dl.acm.org/citation.cfm?id=810616)).
It is perhaps the simplest first attempt in the literature to perform estimation based on the notion of proximity to data locations.

This implementation makes use of k-d trees from the [NearestNeighbors.jl](https://github.com/KristofferC/NearestNeighbors.jl)
package, which leads to a fast estimation method for large or high-resolution spatial domains. Although this method is
recommended for fast assessment of a new field, it has poor statistical properties (lacks covariance model) and should
mainly be used for qualitative purposes.

## Installation

Get the latest stable release with Julia's package manager:

```julia
] add InverseDistanceWeighting
```

## Usage

This package is part of the [GeoStats.jl](https://github.com/juliohm/GeoStats.jl) framework.

For a simple example of usage, please check [this notebook](docs/Usage.ipynb).

## Asking for help

If you have any questions, please [open an issue](https://github.com/juliohm/InverseDistanceWeights.jl/issues).

[travis-img]: https://travis-ci.org/juliohm/InverseDistanceWeighting.jl.svg?branch=master
[travis-url]: https://travis-ci.org/juliohm/InverseDistanceWeighting.jl

[codecov-img]: https://codecov.io/gh/juliohm/InverseDistanceWeighting.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/juliohm/InverseDistanceWeighting.jl
