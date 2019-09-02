# LittleEndianBase128.jl

[![Build
Status](https://travis-ci.org/davidssmith/LittleEndianBase128.jl.svg?branch=master)](https://travis-ci.org/davidssmith/LittleEndianBase128.jl)
[![Build
status](https://ci.appveyor.com/api/projects/status/cl5rx41s7agopqmb?svg=true)](https://ci.appveyor.com/project/davidssmith/leb128-jl)
[![Coverage Status](https://coveralls.io/repos/github/davidssmith/LittleEndianBase128.jl/badge.svg?branch=master)](https://coveralls.io/github/davidssmith/LittleEndianBase128.jl?branch=master)


Little Endian Base 128 (LEB128) encoding and decoding module for the Julia programming language

## Introduction

[LEB128](https://en.wikipedia.org/wiki/LEB128) or Little Endian Base 128 is a form of variable-length code compression
used to store an arbitrarily large integer in a small number of bytes. There are 2 versions of LEB128: unsigned LEB128 and signed LEB128. The decoder must know whether the
encoded value is unsigned LEB128 or signed LEB128.

## Installation

At the Julia prompt, type:
```
julia> Pkg.add("LittleEndianBase128")
```


## Example

```
julia> using LittleEndianBase128

julia> x = rand(-100:100, 3, 3)
3×3 Array{Int64,2}:
 -95   9  -76
 -71  -2   60
  43  57   14

julia> y = encode(x)
12-element Array{UInt8,1}:
 0xbd
 0x01
 0x8d
 0x01
 0x56
 0x12
 0x03
 0x72
 0x97
 0x01
 0x78
 0x1c

julia> z = reshape(decode(y, Int8), 3, 3)
3×3 Array{Int64,2}:
 -95   9  -76
 -71  -2   60
  43  57   14

julia> z = reshape(decodesigned(y), 3, 3)
3×3 Array{Int64,2}:
 -95   9  -76
 -71  -2   60
  43  57   14

julia> z = reshape(decode(y), 3, 3)
3×3 Array{UInt64,2}:
 0x00000000000000bd  0x0000000000000012  0x0000000000000097
 0x000000000000008d  0x0000000000000003  0x0000000000000078
 0x0000000000000056  0x0000000000000072  0x000000000000001c
```

Note that the encoded array is 1-D because the length of each encoded element is not fixed, so a uniform array shaping is not possible.  This is the tradeoff of getting a large compression factor. Consequently when decoding, you'll need to reshape the output back to the original shape, because no shape information is retained within the encoded data.

Also notice that the final decode command assumed that the output is unsigned, so it produced incorrect output. If you have encoded signed data that you wish to decode, then you need to call `decodesigned` or `decode(::Array{UInt8,1}, ::DataType)` with an appropriate signed data type passed in the second argument.

## Getting Help

For help, file an issue on the bug tracker or email one of the authors. Third
party help is welcome and can be contributed through pull requests.

## Authors

David S. Smith, Dong Wang

## Disclaimer

This code comes with no warranty. Use at your own risk. 
