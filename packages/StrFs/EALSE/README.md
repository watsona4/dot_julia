# StrFs

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/tpapp/StrFs.jl.svg?branch=master)](https://travis-ci.com/tpapp/StrFs.jl)
[![codecov.io](http://codecov.io/github/tpapp/StrFs.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/StrFs.jl?branch=master)

Julia packages for strings with fixed maximum number of bytes.

## Overview

`StrF{S} <: AbstractString` can be used for strings up to `S` bytes in [UTF-8](https://en.wikipedia.org/wiki/UTF-8) encoding. When the string has less than that many bytes, it is terminated with a `0x00`.

This mirrors the way [Stata DTA files encode fixed length strings](https://www.stata.com/help.cgi?dta) (`str#`), but other applications may also find this useful. `StrF{S}` strings are implemented by wrapping an `SVector{S,UInt8}`, with the potential efficiency gains that entails.

## Examples

```julia
julia> using StrFs

julia> gender = [strf"male", strf"female"]
2-element Array{StrF{6},1}:
 "male"
 "female"

julia> gender[1] == "male"
true

julia> issorted(gender, rev = true)
true

julia> motto = StrF{6}("ηβπ")          # uses all bytes
"ηβπ"

julia> sizeof(motto)
6

julia> length(motto)
3

julia> motto == StrF{10}("ηβπ")        # 0x00 at byte 7
true
```

## Related

See [StataDTAFiles.jl](https://github.com/tpapp/StataDTAFiles.jl).
