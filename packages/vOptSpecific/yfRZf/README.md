# vOptSpecific: part of vOptSolver for structured problems

[![Build Status](https://travis-ci.org/vOptSolver/vOptSpecific.jl.svg?branch=master)](https://travis-ci.org/vOptSolver/vOptSpecific.jl)
[![codecov.io](http://codecov.io/github/vOptSolver/vOptSpecific.jl/coverage.svg?branch=master)](http://codecov.io/github/vOptSolver/vOptSpecific.jl?branch=master)

**vOptSolver** is a solver of multiobjective linear optimization problems (MOCO, MOIP, MOMILP, MOLP).
This repository concerns **vOptSpecific**, the part of vOptSolver devoted to **multiobjective structured problems** (currently available: 2LAP). With vOptSpecific, the problem is expressed using an Application Programming Interface. vOptSpecific runs on macOS, and linux-ubuntu (local use), also on JuliaBox (distant use).

We suppose you are familiar with vOptSolver; if not, read first this [presentation](https://voptsolver.github.io/vOptSolver/).


## Instructions 
For a local use, a working version of:
- Julia must be ready; instructions for the installation are available [here](https://julialang.org/downloads/)
- your favorite C/C++ compiler must be ready (GCC is suggested)

### Run Julia

On linux or in the cloud (juliaBox):

- open a console on your computer or in the cloud
- when the prompt is ready, type in the console `julia`

On macOS:

- locate the application `julia` and 
- click on the icon, the julia console comes to the screen

### Installation Instructions

Before your first local or distant use, 
1. run Julia and when the terminal is ready with the prompt `julia` on screen, 
2. add and build as follow the mandatory package to your Julia distribution: 

```
julia> Pkg.add("vOptSpecific.jl")
julia> Pkg.build("vOptSpecific")
```

That's all folk; at this point, vOptSpecific is properly installed.

### Usage Instructions

When vOptSpecific is properly installed,

1. run Julia and when the terminal is ready with the prompt `julia` on screen, 
2. invoke vOptSpecific in typing in the console:
```
julia> using vOptSpecific
```
vOptSpecific is ready. See examples for further informations and have fun with the solver!


## Examples 
The folder `examples` provides (1) source code of problems ready to be solved and (2) selected datafiles into different formats.

## Limitations
- The problem size for 2LAP is limited to 100x100.
