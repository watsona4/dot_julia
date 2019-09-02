# PowerDynSolve.jl Changelog

## Version 0.7

* ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [switching to OrdinaryDiffEq instead of DifferentialEquations in order to remove dependencies](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/25)
* ![bugfix](https://img.shields.io/badge/PD-bugfix-%23d73a4a.svg) [fixed: calling solution for a single time point and a single node returned an array with a single element instead of the actual element](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/26)

## Version 0.6

* ![bugfix](https://img.shields.io/badge/PD-bugfix-%23d73a4a.svg) [calling solve on a grid and state that do not belong to each other now raises an AssertionError](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/23)
* ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [added states from grid solution for single time points](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/24)

## Version 0.5

* ![bugfix](https://img.shields.io/badge/PD-bugfix-%23d73a4a.svg) & ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [fix line coverage and testing output](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/20)
* ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [adding functionality for combining multiple grid solutions to one composite grid solution](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/21)

## Version 0.4

* ![bugfix](https://img.shields.io/badge/PD-bugfix-%23d73a4a.svg) & ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [add Julia 1.1. to travis/ci and fixed wrong coverage reporting (thus)](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/18)
* ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [add PowerDynOperationPoint.jl as a subpackage and moved the features of `operationpoint` and `RootFunction` there](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/18)

## Version 0.3

* ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [added CHANGELOG.md](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/13)
* ![enhancement](https://img.shields.io/badge/PD-enhancement-%23a2eeef.svg) [added check whether CHANGELOG.md has been modified to ci/travis](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/14) [(but run that for PRs only, not on branches)](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/17/)
* ![bugfix](https://img.shields.io/badge/PD-bugfix-%23d73a4a.svg) [operationpoint throws now an error instead of a warning when being unsuccesful](https://github.com/JuliaEnergy/PowerDynSolve.jl/pull/12)
