# StochasticIntegrals.jl

| Build | Coverage | Documentation |
|-------|----------|---------------|
| [![Build Status](https://travis-ci.com/s-baumann/StochasticIntegrals.jl.svg?branch=master)](https://travis-ci.org/s-baumann/StochasticIntegrals.jl) | [![Coverage Status](https://coveralls.io/repos/github/s-baumann/StochasticIntegrals.jl/badge.svg?branch=master)](https://coveralls.io/github/s-baumann/StochasticIntegrals.jl?branch=master) | [![docs-latest-img](https://img.shields.io/badge/docs-latest-blue.svg)](https://s-baumann.github.io/StochasticIntegrals.jl/dev/index.html) |

This generates covariance matrices and Cholesky decompositions for a set of stochastic integrals.
At the moment it only supports Ito integrals. Users specify the [MultivariateFunction](https://github.com/s-baumann/MultivariateFunctions.jl) that is the integrand of the ito integral and a covariance matrix will be made of all such Ito integrals.

There are a large number of convenience functions. This includes finding the variance and instantaneous volatility of an ito integral; for extracting the terminal correlation & covariance of a pair of stochastic integrals over a period of time; for generation of random draws from the set of Ito integrals (either pseudorandom or quasirandom). Given a draw of stochastic integrals, it is also possible to find the density of the multivariate normal distribution at this point. See the testing files for code examples.
