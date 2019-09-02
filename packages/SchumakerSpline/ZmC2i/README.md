# SchumakerSpline

| Build | Coverage | Documentation |
|-------|----------|---------------|
| [![Build Status](https://travis-ci.com/s-baumann/SchumakerSpline.jl.svg?branch=master)](https://travis-ci.org/s-baumann/SchumakerSpline.jl) | [![Coverage Status](https://coveralls.io/repos/github/s-baumann/SchumakerSpline.jl/badge.svg?branch=master)](https://coveralls.io/github/s-baumann/SchumakerSpline.jl?branch=master) | [![docs-latest-img](https://img.shields.io/badge/docs-latest-blue.svg)](https://s-baumann.github.io/SchumakerSpline.jl/dev/index.html) |

A Julia package to create a shape preserving spline. This is guaranteed to be monotonic and concave or convex if the data is monotonic and concave or convex. It does not use any optimisation and is therefore quick and smoothly converges to a fixed point in economic dynamics problems including value function iteration. This package has the same functionality as the R package called [schumaker](https://cran.r-project.org/web/packages/schumaker/index.html).
