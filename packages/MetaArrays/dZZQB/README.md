# MetaArrays

[![Build Status](https://travis-ci.org/haberdashPI/MetaArrays.jl.svg?branch=master)](https://travis-ci.org/haberdashPI/MetaArrays.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/bmu8ci97lkaehrlr?svg=true)](https://ci.appveyor.com/project/haberdashPI/metaarrays-jl)
[![codecov](https://codecov.io/gh/haberdashPI/MetaArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/haberdashPI/MetaArrays.jl)

A `MetaArray` stores extra data (usually) as a named tuple along with an
array. The data can be accessed as fields of the array object. It otherwise
behaves much as the stored array.

You create a meta-array by calling `meta` with the specified metadata as keyword
arguments; any operations over the array will preserve the metadata.

For example:

```julia
julia> y = meta(rand(10,10),val1="value1")
julia> x = meta(rand(10,10),val2="value2")

julia> z = x.*y
julia> z.val1
"value1"
```

A `MetaArray` has the same array behavior, broadcasting behavior and strided
array behavior as the wrapped array, while maintaining the metadata. All meta
data is merged using `metamerge` (which defaults to the behavior of `merge`).
You can get the wrapped array using `getcontents` and the metadata tuple
using `getmeta`.

To implement further methods which support maintaining meta-data you can
specialize over `MetaArray{A}` where `A` is the wrapped array type.

For example

```julia
mymethod(x::MetaArray{<:MyArrayType},y::MetaArray{<:MyArrayType}) =
    meta(mymethod(getcontents(x),getcontents(y)),
        MetaArrays.combine(getmeta(x),getmeta(y)))
```

## Merging Metadata

Metadata is merged when two arrays are combined. If you wish to leverage this
merging facility in your own methods of `MetaArray` values you can call
`MetaArrays.combine` which takes two metadata objects and combines them into
a single object using `metamerge`, while checking for any issues when
merging identically named fields.

## AxisArrays

MetaArrays is aware of
[`AxisArrays`](https://github.com/JuliaArrays/AxisArrays.jl) and the wrapped
meta arrays implement a number of the same set of methods as other
`AxisArray` objects.

## Custom metadata types

Sometimes it is useful to dispatch on the type of the metadata rather than
the type of the wrapped array. To make this possible, you can provide a
custom type as metadata rather than fields of a generic, named tuple. This
can be done by passing your custom object `custom` to `MetaData(custom,data)`.
For metadata to appropriately merge you will need to define `metamerge` for
this type. Just as with named tuples, the fields of the custom type can be
accessed directly from the MetaArray.

Once your custom type is defined you can dispatch on the second type parameter
of the MetaArray, like so:

```julia
struct MyCustomMetadata
  val::String
end 

foo(x::MetaArray{<:Any,MyCustomMetadata}) = x.val
x = MetaArray(MyCustomMetadata("Hello, World"),1:10)
println(foo(x))
```
