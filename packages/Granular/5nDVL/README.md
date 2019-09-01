# Granular

![Granular.jl logo](https://github.com/anders-dc/Granular.jl/raw/master/docs/src/assets/logo.gif)

A [Julia](https://julialang.org) package for simulating granular mechanics.

| Referencing | Documentation | Chat | Stable Release | Development Version | Test Coverage |
|:-----------:|:-------------:|:----:|:--------------:|:-------------------:|:-------------:|
| [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1165989.svg)](https://doi.org/10.5281/zenodo.1165989) | [![Granular.jl Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://anders-dc.github.io/Granular.jl/stable) [![Granular.jl Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://anders-dc.github.io/Granular.jl/latest) | [![Chat at https://gitter.im/anders-dc/Granular.jl](https://badges.gitter.im/anders-dc/Granular.jl.svg)](https://gitter.im/anders-dc/Granular.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) | [![Granular](http://pkg.julialang.org/badges/Granular_0.6.svg)](http://pkg.julialang.org/detail/Granular) | [![Build Status](https://travis-ci.org/anders-dc/Granular.jl.svg?branch=master)](https://travis-ci.org/anders-dc/Granular.jl) [![Build Status](https://ci.appveyor.com/api/projects/status/github/anders-dc/Granular.jl?svg=true)](https://ci.appveyor.com/project/anders-dc/seaice-jl/) | [![codecov.io](http://codecov.io/github/anders-dc/Granular.jl/coverage.svg?branch=master)](http://codecov.io/github/anders-dc/Granular.jl?branch=master) |

## Installation
[Granular.jl](https://github.com/anders-dc/Granular.jl) is registered in the 
[official Julia package repository](https://pkg.julialang.org), and the latest 
release can be installed directly from the Julia shell by:

```julia
julia> ]
(v1.0) pkg> add Granular
```

The package contents area installed in the directory 
`~/.julia/packages/Granular`, together with the [required packages](REQUIRE). 
If you want to install the latest development version from the Github 
repository, instead install the package with:

```julia
julia> ]
(v1.0) pkg> add Granular#master
```

You can run the package tests for any version with the following command:

```julia
(v1.0) pkg> test Granular
```

For more information on installation and usage, please refer to the 
[documentation](https://anders-dc.github.io/Granular.jl/latest).

## Author
[Anders Damsgaard](https://adamsgaard.dk), Geophysical Fluid Dynamics 
Laboratory, Princeton University.
