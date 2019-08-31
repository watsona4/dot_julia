# CUDAatomics
Support for atomic operations in [CUDAnative](https://github.com/JuliaGPU/CUDAnative.jl) kernels

## Usage
The functions implemented closely follow the functions in the [CUDA C Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#atomic-functions).  All functions and types included in the guide are supported, and function names are the same as in the guide except that only lowercase characters are used.

The first element to each function will be a `CuDeviceArray` (instead of a pointer as in the C guide).  In addition to the arguments to each function in the C guide, two additional optional arguments are provided for each atomic function:

```
atomicadd(ary, value, [index=1, fieldname=Val(nothing)])
```
`index` specifies which element of the array should be atomically updated, and defaults to the first element.  `fieldname` is a value type used for extending the atomic functions to user-defined types (see below).


## Automatic type conversion
When calling an atomic function such that the `eltype` of the `ary` does not match the type of `value`, the `value` will be automatically converted to the `eltype` of `ary` before the atomic operation is performed.  For instance, one might want to use `threadIdx().x` (which has type `Int64`) to perform a compare-and-swap with a 32-bit integer.

## Extending to user-defined types

The optional `fieldname` argument can be used to specify the field to be updated of a user-defined type.  For instance, to extend `atomicadd` to a dual-number type, one could do

```
struct DualFloat
    value::Float32
    partial::Float32
end

function CUDAatomics.atomicadd(a::CuDeviceArray{DualFloat, N, A}, b::DualFloat, index=1) where {N,A}
    CUDAatomics.atomicadd(a, b.value, index, Val(:value))
    CUDAatomics.atomicadd(a, b.partial, index, Val(:partial))
end
```


