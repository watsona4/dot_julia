# BayesianIntegral

| Build | Coverage | Documentation |
|-------|----------|---------------|
| [![Build Status](https://travis-ci.com/s-baumann/BayesianIntegral.jl.svg?branch=master)](https://travis-ci.org/s-baumann/BayesianIntegral.jl) | [![Coverage Status](https://coveralls.io/repos/github/s-baumann/BayesianIntegral.jl/badge.svg?branch=master)](https://coveralls.io/github/s-baumann/BayesianIntegral.jl?branch=master) | [![docs-latest-img](https://img.shields.io/badge/docs-latest-blue.svg)](https://s-baumann.github.io/BayesianIntegral.jl/dev/index.html) |

This package uses the term Bayesian Integration to mean approximating a function with a kriging metamodel (aka a gaussian process model) and then integrating under it. A kriging metamodel has the nice feature that uncertainty about the nature of the function is explicitly modelled (unlike for instance a approximation with Chebyshev polynomials) and the Bayesian Integral uses this feature to give a Gaussian distribution representing the probabilities of various integral values. The output of the bayesian_integral_gaussian_exponential function is the expectation and variance of this distribution.
