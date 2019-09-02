# MultivariateFunctions.jl

| Build | Coverage | Documentation |
|-------|----------|---------------|
| [![Build Status](https://travis-ci.com/s-baumann/MultivariateFunctions.jl.svg?branch=master)](https://travis-ci.org/s-baumann/MultivariateFunctions.jl) | [![Coverage Status](https://coveralls.io/repos/github/s-baumann/MultivariateFunctions.jl/badge.svg?branch=master)](https://coveralls.io/github/s-baumann/MultivariateFunctions.jl?branch=master) | [![docs-latest-img](https://img.shields.io/badge/docs-latest-blue.svg)](https://s-baumann.github.io/MultivariateFunctions.jl/dev/index.html) |

This implements single algebra and evaluation on Multivariate functions.
There are a few ways in which it can be used.
* This can be used for approximation functions. It can currently implement OLS functions, Chebyshev polynomials, the Schumaker shape preserving spline and basic interpolation schemes. It can also do Recursive Partitioning and create Multivariate Adaptive Regression (MARS) Splines. It could be extended to implement other approximation schemes.
* As in the [StochasticIntegrals.jl](https://github.com/s-baumann/StochasticIntegrals.jl) package this package can be used to define functions that will be the integrands in stochastic integrals. This has the benefit that the means, variances & covariances implied by these stochastic integrals can be found analytically.
* All basic algebra and calculus on a MultivariateFunction can be done analytically.
* Newton's method is implemented so that roots and optima can be found using analytical Jacobians and Hessians.
