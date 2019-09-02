# NumberUnions.jl


#### Copyright © 2016-2018 by Jeffrey Sarnoff. This software is released under The MIT License.

----


 [![][pkg-0.7-img]][pkg-0.7-url]  [![][travis-img]][travis-url]


----


## Type Unions

#### Local Unions

| Union                                      | Types gathered                             |
|:-------------------------------------------|:-------------------------------------------|
| SysInt, SysUInt, SysFloat                  | {Int128 .. Int8}, {UInt128 .. UInt8}, ..   |
| MachInt, MachUInt, MachFloat               | {Int64, Int32}, ..,  {Float64, Float32}    |
| IntFloat64, IntFloat32, IntFloat16         | {Int64, Float64}, {Int32, Float32}, ..     |
| Integer128, Integer64, Integer32, Integer8 | .., {Int64, UInt64},  {Int32, UInt32}, ..  |

#### Imported Unions

Base.IEEEFloat (Union{Float64, Float32, Float16}) is reexported as IEEEFloat


## Type Functions

#### Type from sizeof(type)

- bytes2Int, bytes2UInt, bytes2Float


```julia
using NumberTypeUnions

bytes2Int( sizeof(Int16) )
Int16

bytes2Float( sizeof(Float32) )
Float32
```

----


[travis-img]: https://travis-ci.org/JeffreySarnoff/NumberUnions.jl.svg?branch=master
[travis-url]: https://travis-ci.org/JeffreySarnoff/NumberUnions.jl

[pkg-0.6-img]: http://pkg.julialang.org/badges/NumberUnions_0.6.svg
[pkg-0.6-url]: http://pkg.julialang.org/?pkg=NumberUnions&ver=0.6
[pkg-0.7-img]: http://pkg.julialang.org/badges/NumberUnions_0.7.svg
[pkg-0.7-url]: http://pkg.julialang.org/?pkg=NumberUnions&ver=0.7
