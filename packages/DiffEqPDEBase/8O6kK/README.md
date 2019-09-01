# DiffEqPDEBase.jl

[![Build Status](https://travis-ci.org/JuliaDiffEq/DiffEqPDEBase.jl.svg?branch=master)](https://travis-ci.org/JuliaDiffEq/DiffEqPDEBase.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/sv9xav0c5yn6onkk?svg=true)](https://ci.appveyor.com/project/ChrisRackauckas/diffeqpdebase-jl)
[![Coverage Status](https://coveralls.io/repos/JuliaDiffEq/DiffEqPDEBase.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaDiffEq/DiffEqPDEBase.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaDiffEq/DiffEqPDEBase.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaDiffEq/DiffEqPDEBase.jl?branch=master)

[![DiffEqPDEBase](http://pkg.julialang.org/badges/DiffEqPDEBase_0.5.svg)](http://pkg.julialang.org/?pkg=DiffEqPDEBase)
[![DiffEqPDEBase](http://pkg.julialang.org/badges/DiffEqPDEBase_0.6.svg)](http://pkg.julialang.org/?pkg=DiffEqPDEBase)

DiffEqPDEBase.jl is a component package in the DiffEq ecosystem. It holds the
common types and utility functions which are shared by other component packages
which are related to solving PDEs in order to reduce the size of dependencies.
Additionally, this package holds tools for creating unstructured finite element
meshes to be used in component solver packages.
Users interested in using this functionality in full should check out DifferentialEquations.jl

The documentation for the interfaces here can be found in [DiffEqDocs.jl](https://juliadiffeq.github.io/DiffEqDocs.jl/latest/) and [DiffEqDevDocs.jl](https://juliadiffeq.github.io/DiffEqDevDocs.jl/latest/). Specific parts to note are:

- [Overview](https://juliadiffeq.github.io/DiffEqDevDocs.jl/latest/contributing/ecosystem_overview.html)
- [Developing a Problem](https://juliadiffeq.github.io/DiffEqDevDocs.jl/latest/contributing/defining_problems.html)
- [The Common Solver Options](https://juliadiffeq.github.io/DiffEqDocs.jl/latest/basics/common_solver_opts.html)
- [Performance Overloads Interface](https://juliadiffeq.github.io/DiffEqDocs.jl/latest/features/performance_overloads.html)
