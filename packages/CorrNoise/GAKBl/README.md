# CorrNoise

[![Build Status](https://travis-ci.org/ziotom78/CorrNoise.jl.svg?branch=master)](https://travis-ci.org/ziotom78/CorrNoise.jl)
[![Coverage Status](https://coveralls.io/repos/github/ziotom78/CorrNoise.jl/badge.svg?branch=master)](https://coveralls.io/github/ziotom78/CorrNoise.jl?branch=master)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://ziotom78.github.io/CorrNoise.jl/latest)

CorrNoise.jl is a Julia package to produce streams of correlated
noise, i.e., random numbers which follow a 1/f distribution.

# Example

Here is an example showing how to generate 1/f noise with slope 1.7,
knee frequency sampling frequency 0.05:

```julia
using Random
using CorrNoise
using Plots

rng = OofRNG(GaussRNG(MersenneTwister(1234)), -1.7, 1.15e-5, 0.05, 1.0);
data = [randoof(rng) for i in 1:10000]
plot(data)
```

![](images/example.png)
