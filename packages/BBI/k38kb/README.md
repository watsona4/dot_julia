# BBI.jl
[![Latest Release](https://img.shields.io/github/release/BioJulia/BBI.jl.svg?style=flat-square)](https://github.com/BioJulia/BBI.jl/releases/latest)
[![MIT license](https://img.shields.io/badge/license-MIT-green.svg?style=flat-square)](https://github.com/BioJulia/BBI.jl/blob/master/LICENSE)
[![Stable documentation](https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square)](https://biojulia.github.io/BBI.jl/stable)
[![Latest documentation](https://img.shields.io/badge/docs-latest-blue.svg?style=flat-square)](https://biojulia.github.io/BBI.jl/latest/)
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg?style=flat-square) -->
## Description
BBI handles the shared parts of [bigWig.jl](https://github.com/BioJulia/bigWig.jl) and [bigBed.jl](https://github.com/BioJulia/bigBed.jl).

## Status
<!-- [![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active) -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.org/BioJulia/BBI.jl.svg?branch=master)](https://travis-ci.org/BioJulia/BBI.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/jny2ep4u3cmly8pj/branch/master?svg=true)](https://ci.appveyor.com/project/BioJulia/BBI-jl/branch/master)
[![BBI](http://pkg.julialang.org/badges/BBI_0.7.svg)](http://pkg.julialang.org/?pkg=BBI)
[![BBI](http://pkg.julialang.org/badges/BBI_1.0.svg)](http://pkg.julialang.org/?pkg=BBI)
[![codecov.io](http://codecov.io/github/BioJulia/BBI.jl/coverage.svg?branch=master)](http://codecov.io/github/BioJulia/BBI.jl?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/BioJulia/BBI.jl/badge.svg?branch=master)](https://coveralls.io/github/BioJulia/BBI.jl?branch=master)

## Installation
BBI is bundled into the [bigWig.jl](https://github.com/BioJulia/bigWig.jl) and [bigBed.jl](https://github.com/BioJulia/bigBed.jl)
packages, so you may not need to install this package explicitly.
However, if you do, you can install BBI from the Julia REPL:

```julia
using Pkg
add("BBI")
#Pkg.add("BBI") for julia prior to v0.7
```

If you are interested in the cutting edge of the development, please check out
the `develop` branch to try new features before release.

## Questions?
If you have a question about contributing or using BioJulia software, come
on over and chat to us on [Gitter](https://gitter.im/BioJulia/General), or you can try the
[Bio category of the Julia discourse site](https://discourse.julialang.org/c/domain/bio).
