# TRIANGLE.jl

[![Build Status](https://img.shields.io/travis/cvdlab/Triangle.jl/master.svg?label=Linux+/+macOS)](https://travis-ci.org/cvdlab/Triangle.jl)
[![Windows build status](https://ci.appveyor.com/api/projects/status/s3ngfuitqpsnbgml/branch/master?svg=true)](https://ci.appveyor.com/project/furio/triangle-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/cvdlab/Triangle.jl/badge.svg)](https://coveralls.io/github/cvdlab/Triangle.jl)
[![Read the Docs](https://img.shields.io/readthedocs/pip.svg)](https://cvdlab.github.io/TRIANGLE.jl/)
[![DOI](https://zenodo.org/badge/doi/10.1007/BFb0014497.svg)](http://dx.doi.org/10.1007/BFb0014497)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fcvdlab%2FTriangle.jl.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fcvdlab%2FTriangle.jl?ref=badge_shield)


A Julia interface to Jonathan Richard Shewchuk [Triangle](https://www.cs.cmu.edu/~quake/triangle.html).

### Library notes
At the moment the library will use only CDT, planning to expand later.

### Licensing note

Note that while this binding-library is under a permissive license ([MIT](LICENSE)), the original [Triangle](https://www.cs.cmu.edu/~quake/triangle.html) library isn't:
> Please note that although Triangle is freely available, it is copyrighted by the author and may not be sold or included in commercial products without a license.

So be wary of any possible conflict between your project license and [Triangle](https://www.cs.cmu.edu/~quake/triangle.html)'s

## Installation
```julia
using Pkg
add("Triangle")

# Pkg.add("Triangle") on julia prior to v0.7
```

### Windows

The build proces uses VC++ binary to build so be sure you have it before running the build part.

## API

Include the module (`using Triangle`).

You can use Julia `?Triangle.methodname` for inline documentation. Documentation can be read on https://cvdlab.github.io/Triangle.jl/ .
