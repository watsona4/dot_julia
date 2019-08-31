# BitConverter.jl

Converts base data types to an array of bytes, and an array of bytes to base
data types.
So far Integer only are implemented.

[![pipeline status](https://gitlab.com/braneproject/bitconverter.jl/badges/master/pipeline.svg)](https://gitlab.com/braneproject/bitconverter.jl/commits/master)  [![coverage report](https://gitlab.com/braneproject/bitconverter.jl/badges/master/coverage.svg)](https://gitlab.com/braneproject/bitconverter.jl/commits/master)

## Examples

```julia
julia> bytes(big(2)^32)
5-element Array{UInt8,1}:
 0x01
 0x00
 0x00
 0x00
 0x00
```

```julia
julia> to_big(rand(UInt8, 8))
15240817377628901573

julia> to_int(rand(UInt8, 2))
48868

julia> to_int(rand(UInt8, 8))
-3411029373876830527
```

## Documentation

https://braneproject.gitlab.io/bitconverter.jl

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:34nvxratCQcQgtbwxMJfkmmxwrxtShTn67)
