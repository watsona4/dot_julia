[![Build Status](https://travis-ci.org/sisl/LocalFunctionApproximation.jl.svg?branch=master)](https://travis-ci.org/sisl/LocalFunctionApproximation.jl)
[![Coverage Status](https://coveralls.io/repos/github/sisl/LocalFunctionApproximation.jl/badge.svg?branch=master)](https://coveralls.io/github/sisl/LocalFunctionApproximation.jl?branch=master)

# LocalFunctionApproximation

This package provides local function approximators that interpolates a scalar-valued function across a vector space. It does so based on the values of the function at "nearby" points, based on an appropriate locality metric, and not via any global regression or fitting function. Currently it supports multi-linear and simplex interpolations for multi-dimensional grids, and k-nearest-neighbor
interpolation. Two important dependencies are [GridInterpolations](https://github.com/sisl/GridInterpolations.jl/blob/master/src/GridInterpolations.jl)
and [NearestNeighbors](https://github.com/KristofferC/NearestNeighbors.jl).

## Installation and Usage

Start Julia and run the following:

```julia
Pkg.add("LocalFunctionApproximation")
using LocalFunctionApproximation
```

## Create Function Approximators

Create a rectangular grid for interpolation using `GridInterpolations` and create the function approximator
that uses it:

```julia
using GridInterpolations # Make the grid interpolations module available
grid = RectangleGrid([0., 0.5, 1.],[0., 0.5, 1.])      # rectangular grid
grid_values = [8., 1., 6., 3., 5., 7., 4., 9., 2.]     # corresponding values at each grid point
gifa = LocalGIFunctionApproximator(grid, grid_values)  # create the function approximator using the grid and values
```

Create a nearest neighbor tree using `NearestNeighbors` and create the corresponding approximator:

```julia
using NearestNeighbors, StaticArrays
points = [SVector(0.,0.), SVector(0.,1.), SVector(1.,1.), SVector(1.,0.)]   # the 4 corners of the unit square
nntree = KDTree(points)                                                     # create a KDTree using the points
vals = [1., 1., -1., -1]                                                    # values corresponding to points
k = 2                                                                       # the k parameter for knn approximator
knnfa = LocalNNFunctionApproximator(nntree, points, k)
```


## Compute values at arbitrary points

```julia
point = rand(2)             # random 2D point
compute_value(gifa, point)  # obtain the value by interpolating the function at that point       
compute_value(knnfa, point) # do the same for the kNN approximator
```

A typical use case for this package is for Local Approximation Value Iteration, as shown [here](https://github.com/Shushman/LocalApproximationValueIteration.jl).
