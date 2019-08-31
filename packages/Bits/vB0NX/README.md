# Bits

[![Build Status](https://travis-ci.org/rfourquet/Bits.jl.svg?branch=master)](https://travis-ci.org/rfourquet/Bits.jl)

This package implements functions to play with bits, of integers, and of floats to a certain extent.
For example:
```julia
julia> bits(0b110101011)
<00000001 10101011>

julia> ans[1:4]
<1011>
```

Currently, the following functions are exported:
`bit`, `bits`, `bitsize`, `low0`, `low1`, `mask`, `masked`, `scan0`, `scan1`, `tstbit`, `weight`.
They have a docstring, but no HTML documentation is available yet.

In these functions, the right-most bit of a value has index `1`, but in some applications it's more natural for it to have index `0`.
So the functions will likely be also implemented with indexes starting at `0`, and both alternatives will be available.
It's possible that the default will be changed.
