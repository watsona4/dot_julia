# ConsistencyResampling.jl

Consistency resampling of calibrated predictions.

[![Build Status](https://travis-ci.com/devmotion/ConsistencyResampling.jl.svg?branch=master)](https://travis-ci.com/devmotion/ConsistencyResampling.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/devmotion/ConsistencyResampling.jl?svg=true)](https://ci.appveyor.com/project/devmotion/ConsistencyResampling-jl)
[![DOI](https://zenodo.org/badge/186521141.svg)](https://zenodo.org/badge/latestdoi/186521141)
[![Codecov](https://codecov.io/gh/devmotion/ConsistencyResampling.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/devmotion/ConsistencyResampling.jl)
[![Coveralls](https://coveralls.io/repos/github/devmotion/ConsistencyResampling.jl/badge.svg?branch=master)](https://coveralls.io/github/devmotion/ConsistencyResampling.jl?branch=master)

## Overview

This package implements consistency resampling in the Julia language, as described by [Bröcker and Smith (2007)](https://doi.org/10.1175/WAF993.1).
It is based on the [`Bootstrap.jl`](https://github.com/juliangehring/Bootstrap.jl) package for statistical bootstrapping in Julia.

Consistency resampling is a resampling technique that generates calibrated predictions from a data set of predictions
and corresponding labels. First a set of predictions is sampled from the data set with replacement. In a second step
artificial labels are sampled with the predicted probabilities. This resampling procedure ensures that the predictions
are calibrated for the artificial labels.

## Example

The predictions have to be provided as a matrix of size `(m, n)`, in which each of the `n` columns corresponds to
predicted probabilities of the labels `1,…,m`. The corresponding labels have to be provided as a vector of length `n`,
in which every element is from the set `1,…,m`.

```julia
predictions = rand(10, 500)
predictions ./= sum(predictions, dims=1)

labels = rand(1:10, 500)
```

Consistency resampling is performed similar to the other bootstrapping approaches in `Bootstrap.jl`. A random number
generator can be provided as optional argument.

```julia
using ConsistencyResampling
using Distances
using Flux: onehotbatch

b = bootstrap((predictions, labels), ConsistentSampling(100_000)) do (x, y)
  totalvariation(x, onehotbatch(y, 1:10)) / 500
end
```

The bootstrapped samples can be explored and used for estimation of confidence intervals, as explained
in the documentation of `Bootstrap.jl`.

## References

Bröcker, J. and Smith, L.A., 2007. Increasing the reliability of reliability diagrams. Weather and forecasting, 22(3), pp. 651-661.
