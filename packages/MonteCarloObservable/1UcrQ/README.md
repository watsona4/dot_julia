![logo](https://github.com/crstnbr/MonteCarloObservable.jl/blob/master/docs/src/assets/logo_with_text.png)

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://crstnbr.github.io/MonteCarloObservable.jl/latest)
[![travis][travis-img]](https://travis-ci.org/crstnbr/MonteCarloObservable.jl)
[![appveyor][appveyor-img]](https://ci.appveyor.com/project/crstnbr/montecarloobservable-jl/branch/master)
[![codecov][codecov-img]](http://codecov.io/github/crstnbr/MonteCarloObservable.jl?branch=master)
[![license: MIT](https://img.shields.io/badge/License-MIT-red.svg)](https://opensource.org/licenses/MIT)

[travis-img]: https://img.shields.io/travis/crstnbr/MonteCarloObservable.jl/master.svg?label=Linux
[appveyor-img]: https://img.shields.io/appveyor/ci/crstnbr/montecarloobservable-jl/master.svg?label=Windows
[codecov-img]: https://img.shields.io/codecov/c/github/crstnbr/MonteCarloObservable.jl/master.svg?label=codecov

An implementation of an observable for Markov Chain Monte Carlo simulations (like the currently out-dated [MonteCarlo.jl](https://github.com/crstnbr/MonteCarlo.jl)).

During a [Markov chain Monte Carlo simulation](https://en.wikipedia.org/wiki/Markov_chain_Monte_Carlo) a Markov walker (after thermalization) walks through configuration space according to the equilibrium distribution. Typically, one measures observables along the Markov path, records the results, and in the end averages the measurements. `MonteCarloObservable.jl` provides all the necessary tools for conveniently conducting these types of measurements, including estimation of one-sigma error bars through binning or jackknife analysis.

### Installation

In the REPL, switch to pkg mode (by pressing `]`) and enter
```julia
add MonteCarloObservable
```

Alternatively, you can install the package per
```julia
using Pkg
Pkg.add("MonteCarloObservable")
```

### Documentation

Look at the [documentation](https://crstnbr.github.io/MonteCarloObservable.jl/latest) for more information.
