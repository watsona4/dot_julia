# KernelDensityEstimatePlotting.jl

[![Build Status](https://travis-ci.org/JuliaRobotics/KernelDensityEstimatePlotting.jl.svg?branch=master)](https://travis-ci.org/JuliaRobotics/KernelDensityEstimatePlotting.jl)
[![codecov.io](https://codecov.io/github/JuliaRobotics/KernelDensityEstimatePlotting.jl/coverage.svg?branch=master)](https://codecov.io/github/JuliaRobotics/KernelDensityEstimatePlotting.jl?branch=master)

[![KernelDensityEstimatePlotting](http://pkg.julialang.org/badges/KernelDensityEstimatePlotting_0.6.svg)](http://pkg.julialang.org/?pkg=KernelDensityEstimatePlotting&ver=0.6)
[![KernelDensityEstimatePlotting](http://pkg.julialang.org/badges/KernelDensityEstimatePlotting_0.7.svg)](http://pkg.julialang.org/?pkg=KernelDensityEstimatePlotting&ver=0.7)
[![KernelDensityEstimatePlotting](http://pkg.julialang.org/badges/KernelDensityEstimatePlotting_1.0.svg)](http://pkg.julialang.org/?pkg=KernelDensityEstimatePlotting&ver=1.0)

This package provides the plotting functionality for the [KernelDensityEstimate.jl](https://github.com/JuliaRobotics/KernelDensityEstimate.jl) package, and currently only supports the Gadfly back-end.

This package is also used extensively by the [RoMEPlotting.jl](https://github.com/dehann/RoMEPlotting.jl) package.

# Install

This package can be installed with:
```julia
julia> ] # to activate package manager
pkg> add KernelDensityEstimatePlotting
```


# Usage

## Basic Examples

```julia
using KernelDensityEstimate, KernelDensityEstimatePlotting

p = kde!(randn(3,100))
plot(marginal(p, [1]))
plot(marginal(p, [2,3]))
plot(p)
```
## More Examples

Please see examples on [KernelDensityEstimate.jl](https://github.com/JuliaRobotics/KernelDensityEstimate.jl).
