# RunLengthArrays

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ziotom78.github.io/RunLengthArrays.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ziotom78.github.io/RunLengthArrays.jl/dev)
[![Build Status](https://travis-ci.com/ziotom78/RunLengthArrays.jl.svg?branch=master)](https://travis-ci.com/ziotom78/RunLengthArrays.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/ziotom78/RunLengthArrays.jl?svg=true)](https://ci.appveyor.com/project/ziotom78/RunLengthArrays-jl)
[![Codecov](https://codecov.io/gh/ziotom78/RunLengthArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ziotom78/RunLengthArrays.jl)

This Julia package implements a `RunLengthArray{N,T}` type that behaves like a
1D array but is extremely efficient if there are several repeating instances of
a few values, like in the following example:

```julia
using RunLengthArrays

x = RunLengthArray{Int,String}(["X", "X", "X", "X", "O", "O", "O", "O", "O"])
```

More information is available in the documentation.

## License

The code is released under a MIT license.
