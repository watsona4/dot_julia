# ErdosExtras.jl

[![Build Status](https://travis-ci.org/CarloLucibello/ErdosExtras.jl.svg?branch=master)](https://travis-ci.org/CarloLucibello/ErdosExtras.jl)
[![codecov.io](http://codecov.io/github/CarloLucibello/ErdosExtras.jl/coverage.svg?branch=master)](http://codecov.io/github/CarloLucibello/ErdosExtras.jl?branch=master)

More algorithms for the [Erdos.jl](https://github.com/CarloLucibello/Erdos.jl) graph library.
This package contains

- Travelling Salesman Problem
- minimum weight perfect b-matching
- maximum weight matching on arbitrary graphs (through BlossomV algorithm)

## Installation
The library `libgmp-dev` to build [GPLK](https://github.com/JuliaOpt/GLPK.jl) on Linux systems is required.
Install *ErdosExtras* with
```julia
]add ErdosExtras
```
