# StanDump

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.org/tpapp/StanDump.jl.svg?branch=master)](https://travis-ci.org/tpapp/StanDump.jl)
[![Coverage Status](https://coveralls.io/repos/tpapp/StanDump.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tpapp/StanDump.jl?branch=master)

Julia package for saving *data* (arrays and scalars) in a format that can be read by [`cmdstan`](http://mc-stan.org/interfaces/cmdstan.html).

# Example usage

```julia
N = 200
stan_dump("/tmp/test.data.R", (N = N, x = randn(N)))
```

`stan_dump(target, data)` is the main entry point. The first argument is usually a filename (see its docstring for other options), while the `data` is specified as a `NamedTuple`.

Variable names are minimally validated. Only supports types understood by `cmdstan`.
