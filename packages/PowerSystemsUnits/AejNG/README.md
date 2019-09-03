# PowerSystemsUnits

[![Build Status](https://travis-ci.com/invenia/PowerSystemsUnits.jl.svg?branch=master)](https://travis-ci.com/invenia/PowerSystemsUnits.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/invenia/PowerSystemsUnits.jl?svg=true)](https://ci.appveyor.com/project/invenia/PowerSystemsUnits-jl)
[![CodeCov](https://codecov.io/gh/invenia/PowerSystemsUnits.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/PowerSystemsUnits.jl)


A supplemental power systems units package for [Unitful 0.1.0](https://github.com/ajkeller34/Unitful.jl.git) or later.


## Usage

Modules that use PowerSystemsUnits will typically have to explicitly register
PowerSystemsUnits with Unitful because precompilation is not currently supported:

```julia
using Unitful
using PowerSystemsUnits

Unitful.register(PowerSystemsUnits)
```
