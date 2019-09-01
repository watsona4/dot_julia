[![Build Status](https://travis-ci.org/JuliaComputing/FixedSizeStrings.jl.svg?branch=master)](https://travis-ci.org/JuliaComputing/FixedSizeStrings.jl)

[![codecov.io](http://codecov.io/github/JuliaComputing/FixedSizeStrings.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaComputing/FixedSizeStrings.jl?branch=master)

# FixedSizeStrings.jl

This is a string type for compactly storing short strings of statically-known size.
Each character is stored in one byte, so currently only the Latin-1 subset of Unicode is supported.

To use, call `FixedSizeString{n}(itr)`, where `n` is the length and `itr` is an iterable
of characters. Alternatively, other string types can be converted to `FixedSizeString{n}`.

FixedSizeStrings works well in the following cases:

- Very short strings, e.g. <= 8 characters
- Storing many strings of the same length, when the number of unique strings is large

If you have a large array with a relatively small number of unique strings, it is
probably better to use `PooledArrays` with whatever string type is convenient.

TODO and open questions:

- Support more characters by adding a parameter for the representation (UInt16, UInt32)
- Does it make sense to support UTF-8?
- Possibly add `MaxLengthString`, which is the same except can be padded with 0 bytes to represent fewer than the maximum possible number of characters.
