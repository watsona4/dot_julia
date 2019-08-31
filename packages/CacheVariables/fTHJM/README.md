# CacheVariables.jl

[![Build Status](https://travis-ci.org/dahong67/CacheVariables.jl.svg?branch=master)](https://travis-ci.org/dahong67/CacheVariables.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/4d7heef207rl9url?svg=true)](https://ci.appveyor.com/project/dahong67/cachevariables-jl)
[![codecov](https://codecov.io/gh/dahong67/CacheVariables.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dahong67/CacheVariables.jl)

Save outputs from (expensive) computations.

```julia
@cache "test.bson" begin
  a = "a very time-consuming quantity to compute"
  b = "a very long simulation to run"
  100
end
```

The first time this block runs,
it identifies the variables `a` and `b` and saves them
(in addition to the final output `100` that is saved as `ans`)
in a BSON file called `test.bson`.
Subsequent runs load the saved values from the file `test.bson`
rather than re-running the potentially time-consuming computations!
Especially handy for long simulations.

An example of the output:

```julia
julia> using CacheVariables

julia> @cache "test.bson" begin
         a = "a very time-consuming quantity to compute"
         b = "a very long simulation to run"
         100
       end
┌ Info: Saving to test.bson
│ a
└ b
100

julia> @cache "test.bson" begin
         a = "a very time-consuming quantity to compute"
         b = "a very long simulation to run"
         100
       end
┌ Info: Loading from test.bson
│ a
└ b
100
```

An optional `overwrite` flag (default is false) at the end
tells the macro to always save,
even when a file with the given name already exists.

```julia
julia> @cache "test.bson" begin
         a = "a very time-consuming quantity to compute"
         b = "a very long simulation to run"
         100
       end false
┌ Info: Loading from test.bson
│ a
└ b
100

julia> @cache "test.bson" begin
         a = "a very time-consuming quantity to compute"
         b = "a very long simulation to run"
         100
       end true
┌ Info: Overwriting test.bson
│ a
└ b
100
```

## Caveats
+ The variable name `ans` is used for storing the output (`100` in the above examples),
so it is best to avoid using this as a variable name.
