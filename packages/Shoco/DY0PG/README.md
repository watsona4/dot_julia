# Shoco.jl

[![Shoco](http://pkg.julialang.org/badges/Shoco_0.7.svg)](http://pkg.julialang.org/?pkg=Shoco)
[![Build Status](https://travis-ci.org/ararslan/Shoco.jl.svg?branch=master)](https://travis-ci.org/ararslan/Shoco.jl)
[![Coverage Status](https://coveralls.io/repos/github/ararslan/Shoco.jl/badge.svg?branch=master)](https://coveralls.io/github/ararslan/Shoco.jl?branch=master)

**Shoco.jl** is a Julia package that provides access to the compression and decompression functions in the [**Shoco**](https://github.com/Ed-von-Schleck/shoco) C library.
The algorithms are optimized for short strings and perform well in comparison to [smaz](https://github.com/antirez/smaz), [gzip](https://en.wikipedia.org/wiki/Gzip), and [xz](https://en.wikipedia.org/wiki/Xz).
Compression is performed using [entropy encoding](https://en.wikipedia.org/wiki/Entropy_encoding).

Two functions are exported by this package: `compress` and `decompress`.
Both accept a single `AbstractString` argument and return a `String`.
It's important to note that the output from `compress` may not be valid UTF-8, which the `String` type doesn't care about, but your use case might.

Here's an example using the functions at the REPL.

```julia
julia> using Shoco

julia> compress("what's happening")
"؉'s ⎨<g"

julia> decompress("؉'s ⎨<g")
"what's happening"
```

The Shoco C library does not work on Windows due to lack of C99 support, which means that this package has the same restriction.
