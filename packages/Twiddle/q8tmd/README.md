# Twiddle.jl

[![](https://img.shields.io/github/release/BenJWard/Twiddle.jl.svg)](https://github.com/BenJWard/Twiddle.jl/releases/latest)
[![](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/BenJWard/Twiddle.jl/blob/master/LICENSE)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://BenJWard.github.io/Twiddle.jl/stable)
[![](https://travis-ci.org/BenJWard/Twiddle.jl.svg?branch=master)](https://travis-ci.org/BenJWard/Twiddle.jl)
[![](https://ci.appveyor.com/api/projects/status/cxxjc32mrjl3re12/branch/master?svg=true)](https://ci.appveyor.com/project/BenJWard/twiddle-jl/branch/master)

## Description

Twiddle is a package collecting useful bit-twiddling tricks, ready to use as
functions, with detailed documentation of what they do, and example real-world
use cases.

This package originated from a PostDoc project where we wanted to do some common
biological sequence operations much much faster than a naive implementation
could, by taking advantage of succinct bit-encoding of the sequences.

This package however is supposed to be more general, and we want it to contain
many bit-twiddling tips and tricks.


## Installation

Install BioSequences from the Julia REPL:

```julia
using Pkg
Pkg.add("Twiddle")
```

If you are interested in the cutting edge of the development, please check out
the master branch to try new features before release.
