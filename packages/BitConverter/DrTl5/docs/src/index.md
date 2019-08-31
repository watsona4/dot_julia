# BitConverter.jl

Converts base data types to an array of bytes, and an array of bytes to base
data types.
So far Integer only are implemented.

## Functions

```@docs
bytes(x::Integer; len::Integer, little_endian::Bool)
to_big(x::Vector{UInt8})
to_int(x::Vector{UInt8}; little_endian::Bool)
```

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:1786ytdyKz1TJgpVM34DKDB85eEQkvwgjo)

## Index

```@index
```
