[![Build Status](https://travis-ci.org/Crghilardi/ForestBiometrics.jl.svg?branch=master)](https://travis-ci.org/Crghilardi/ForestBiometrics.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/ltey9skqhs40let0/branch/master?svg=true)](https://ci.appveyor.com/project/Crghilardi/forestbiometrics-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/Crghilardi/ForestBiometrics.jl/badge.svg?branch=master)](https://coveralls.io/github/Crghilardi/ForestBiometrics.jl?branch=master)


# ForestBiometrics.jl
A package for various forest mensuration and biometrics functions in Julia

ForestBiometrics.jl is a package for working with forest measurements data and growth and yield modeling.
This package was inspired by its R counterpart, the [lmfor package](https://CRAN.R-project.org/package=lmfor) with the addition of equations from the western US. For more info on lmfor, please see http://cs.uef.fi/~lamehtat/rcodes.htm

It is my hope that the package not only ports existing functionality from other languages, but also showcases the abilities of Julia as a programming language and how concepts like multiple dispatch and metaprogramming can be used to solve domain-specific problems.

** **Currently in the process of updating since the 1.0.X release, so things may be in flux or broken** **

## Documentation

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://crghilardi.github.io/ForestBiometrics.jl/latest)


## Installation

`] add ForestBiometrics`

If you are interested in this package and would like to contribute, feel free to submit an issue or pull request.

## Dependencies

The following Julia packages are used in this package:

- PlotRecipes for plotting functionality
- OffsetArrays.jl for creating lookup tables for Scribner Decimal C scaling

## Example outputs

Gingrich stocking guides

<img src="https://raw.githubusercontent.com/Crghilardi/ForestBiometrics.jl/master/examples/Gingrich_chart_example.png" align="middle"  />

SDI chart with lines at 100%, 55% and 35% max SDI

<img src="https://raw.githubusercontent.com/Crghilardi/ForestBiometrics.jl/master/examples/SDI_chart_example.png" align="middle"  />


Walkthroughs

I am creating a series of short examples walking through topical problems and how this package can be used to solve those problems. They can be found in this repo under examples/walkthroughs or from the links below.

Examples include:

[HeightDiameter](https://github.com/Crghilardi/ForestBiometrics.jl/blob/master/examples/walkthroughs/HeightDiameter_walkthrough.ipynb)

[Stand exam calculations](https://github.com/Crghilardi/ForestBiometrics.jl/blob/master/examples/walkthroughs/stand_calculations.ipynb)
