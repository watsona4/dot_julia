# PyDSTool.jl

[![Build Status](https://travis-ci.org/JuliaDiffEq/PyDSTool.jl.svg?branch=master)](https://travis-ci.org/JuliaDiffEq/PyDSTool.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/qgi1m49ruthu3bh5?svg=true)](https://ci.appveyor.com/project/ChrisRackauckas/pydstool-jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaDiffEq/PyDSTool.jl/badge.svg)](https://coveralls.io/github/JuliaDiffEq/PyDSTool.jl)
[![codecov.io](http://codecov.io/github/JuliaDiffEq/PyDSTool.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaDiffEq/PyDSTool.jl?branch=master)

PyDSTool.jl is a wrapper for the PyDSTool Python library for analysis of dynamical
systems. This wrapper includes three parts:

1) Installation and direct access to PyDSTool
2) A low-level development API and provides some functionality to make directly dealing
   with the library a little bit easier, but still requires knowledge of PyDSTool itself.
3) A high-level API for usage with DifferentialEquations

The tests show how to use the functionality.
It is used as an addon in the DifferentialEquations.jl ecosystem. It is recommended
that users use this functionality through [DifferentialEquations.jl](https://github.com/JuliaDiffEq/DifferentialEquations.jl).
