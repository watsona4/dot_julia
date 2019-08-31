# BayesOpt

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.org/jbrea/BayesOpt.jl.svg?branch=master)](https://travis-ci.org/jbrea/BayesOpt.jl)
[![codecov.io](http://codecov.io/github/jbrea/BayesOpt.jl/coverage.svg?branch=master)](http://codecov.io/github/jbrea/BayesOpt.jl?branch=master)

[Julia](https://julialang.org) wrapper of [BayesOpt](https://github.com/rmcantin/bayesopt/).

## Usage

```julia
using BayesOpt
config = ConfigParameters()         # calls initialize_parameters_to_default of the C API
set_kernel!(config, "kMaternARD5")  # calls set_kernel of the C API
config.sc_type = SC_MAP
f(x) = sum(x .^ 2)
lowerbound = [-2., -2.]; upperbound = [2., 2.]
optimizer, optimum = bayes_optimization(f, lowerbound, upperbound, config)
```

Consult the [BayesOpt documentation](https://rmcantin.bitbucket.io/html/usemanual.html)
for the configuration options.
