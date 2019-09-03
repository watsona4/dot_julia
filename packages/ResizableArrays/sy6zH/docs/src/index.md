# Introduction

The ResizableArray package provides multi-dimensional arrays which are
resizable and which are intended to be as efficient as Julia arrays.  This
circumvents the Julia limitation that only uni-dimensional arrays (of type
`Vector`) are resizable.  The only restriction is that the number of dimensions
of a resizable array must be left unchanged.

Resizable arrays may be useful in a variety of situations.  For instance to
avoid re-creating arrays and therefore to limit the calls to Julia garbage
collector which may be very costly for real-time applications.

Unlike [ElasticArrays](https://github.com/JuliaArrays/ElasticArrays.jl) which
provides arrays that can grow and shrink, but only in their last dimension, any
dimensions of ResizableArray instances can be changed (providing the number of
dimensions remain the same).  Another difference is that you may use a custom
Julia object to store the elements of a resizable array, not just a
`Vector{T}`.

The source code of ResizableArrays is available on
[GitHub](https://github.com/emmt/ResizableArrays.jl).


## Table of contents

```@contents
Pages = ["install.md", "usage.md", "library.md"]
```

## Index

```@index
```
