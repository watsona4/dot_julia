# Twiddle.jl

[![Latest Release](https://img.shields.io/github/release/Ward9250/Twiddle.jl.svg)](https://github.com/Ward9250/Twiddle.jl/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/Ward9250/Twiddle.jl/blob/master/LICENSE)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://Ward9250.github.io/Twiddle.jl/stable)
[![Twiddle](http://pkg.julialang.org/badges/Twiddle_0.7.svg)](http://pkg.julialang.org/?pkg=Twiddle)
[![Twiddle](http://pkg.julialang.org/badges/Twiddle_1.0.svg)](http://pkg.julialang.org/?pkg=Twiddle)
[![Build Status](https://travis-ci.org/BenJWard/Twiddle.jl.svg?branch=master)](https://travis-ci.org/BenJWard/Twiddle.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/cxxjc32mrjl3re12/branch/master?svg=true)](https://ci.appveyor.com/project/BenJWard/twiddle-jl/branch/master)


## Description

Twiddle is a package collecting useful bit-twiddling tricks, ready to use as
functions, with detailed documentation of what they do, and example real-world
use cases.

This package originated from a PostDoc project where we wanted to do some common
biological sequence operations much much faster than a naive implementation
could, by taking advantage of succinct bit-encoding of the sequences.

This package however is supposed to be more general, and we want it to contain
many bit-twiddling tips and tricks.


## Quick Start

Install the latest version of Twiddle from the Julia REPL:

```@example qs
using Pkg
Pkg.add("Twiddle")
```

To use any functions in Twiddle, you must _fully qualify_ the name e.g.

```@example qs
using Twiddle

Twiddle.count_nonzero_nibbles(0x0F11F111F11111F1)
```

Alternatively, explicitly import the name e.g.

```@example qs
using Twiddle: count_nonzero_nibbles

count_nonzero_nibbles(0x0F11F111F11111F1)
```
