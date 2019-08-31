# BeliefUpdaters.jl

[![Build Status](https://travis-ci.org/JuliaPOMDP/BeliefUpdaters.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/BeliefUpdaters.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaPOMDP/BeliefUpdaters.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaPOMDP/BeliefUpdaters.jl?branch=master)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://JuliaPOMDP.github.io/BeliefUpdaters.jl/latest)

Collection of belief updaters and belief representation for POMDPs.jl. Particle filters are not included in this package, but an implementation can be found in [ParticleFilters.jl](https://github.com/JuliaPOMDP/ParticleFilters.jl).

This is a supported [JuliaPOMDP](https://github.com/JuliaPOMDP) package.

The documentation can be found here: https://juliapomdp.github.io/BeliefUpdaters.jl/latest

## Installation

```julia
using Pkg
Pkg.add("BeliefUpdaters")
```

## Code structure

Within src each file contains one tool. Each file should clearly indicate who is the maintainer of that file.
