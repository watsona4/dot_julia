# LinearFractional

<!-- [![Coverage Status](https://coveralls.io/repos/focusenergy/LinearFractional.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/focusenergy/LinearFractional.jl?branch=master) -->
[![Travis Build Status](https://travis-ci.org/focusenergy/LinearFractional.jl.svg?branch=master)](https://travis-ci.org/focusenergy/LinearFractional.jl)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)

LinearFractional is an extension for [JuMP](https://github.com/JuliaOpt/JuMP.jl) to optimize linear programs with fractional objectives.  LinearFractional implements the [Charnes-Cooper transformation](https://en.wikipedia.org/wiki/Linear-fractional_programming) behind-the-scenes so that the user only needs to specify the problem as any ordinary JuMP problem, but specifying a numerator and denominator instead of a single objective function.


## Installation

To install the latest development version, run the following command:

```julia
using Pkg
Pkg.add("LinearFractional")
```

Then you can run the built-in unit tests with

```julia
Pkg.test("LinearFractional")
```

to verify that everything is functioning properly on your machine.

## Basic Example

This toy example refers to the reference problem in http://www.ams.jhu.edu/~castello/625.414/Handouts/FractionalProg.pdf.

```julia
using LinearFractional
using JuMP
using Clp

lfp = LinearFractionalModel(solver=ClpSolver())
x1 = @variable(lfp, basename="x1", lowerbound=0)
x2 = @variable(lfp, basename="x2", lowerbound=0, upperbound=6)
@constraint(lfp, -x1 + x2 <= 4)
@constraint(lfp, 2x1 + x2 <= 14)
@constraint(lfp, x2 <= 6)
@numerator(lfp,  :Min, -2x1 + x2 + 2)
@denominator(lfp,  x1 + 3x2 + 4)
solve(lfp)
getobjectivevalue(lfp)
getvalue(x1)
getvalue(x2)
```
