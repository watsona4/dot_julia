# UnalignedVectors

[![Build Status](https://travis-ci.org/JuliaArrays/UnalignedVectors.jl.svg?branch=master)](https://travis-ci.org/JuliaArrays/UnalignedVectors.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/e5s72r50g0xix7o6/branch/master?svg=true)](https://ci.appveyor.com/project/timholy/unalignedvectors-jl/branch/master)
[![codecov.io](http://codecov.io/github/JuliaArrays/UnalignedVectors.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaArrays/UnalignedVectors.jl?branch=master)

Julia allows you to create arrays from a pointer to a memory buffer,
but an `Array{T}` requires a pointer that is a multiple of
`sizeof(T)`. This package allows you to create an `AbstractArray` with
element type `T` even when the pointer lacks proper alignment.

## Usage example: memory mapping

A common usage might be memory mapping, using Julia's `Mmap.mmap`
functionality. Let's create a fake file format with the following
structure:

- magic bytes "BIGARRAY" followed a newline
- the number of dimensions in the array
- the size of the array
- the data of the array (always `Float64`)

The rub is that the data will always start with an odd offset, because
the magic bytes (plus the newline) total 9 bytes, and the dimension
information always adds an even number of types. As a consequence, the
memory buffer is not properly aligned for `Float64` (which requires
the pointer address to be a multiple of 8) and consequently ordinary
`mmap` operations will fail.

To try this out, first let's write such a file:

```julia
open("/tmp/testfile.bga", "w") do io
    write(io, "BIGARRAY\n")
    A = [1.0 2.0;
         3.0 4.0]
    write(io, ndims(A))
    for s in size(A)
        write(io, s)
    end
    write(io, A)
end
```

Now let's create a format reader (note that the best way to define a
new format is using [FileIO](https://github.com/JuliaIO/FileIO.jl),
but for simplicity we'll keep things very low level):

```julia
function reader(io)
    String(read(io, 9)) == "BIGARRAY\n" || error("file is not a BIGARRAY file")
    n = read(io, Int)             # read the number of dimensions
    sz = (read(io, Int, n)...)    # read the size
    # Mmap the buffer:
    a = Mmap.mmap(io, Vector{UInt8}, sizeof(Float64)*prod(sz), position(io))
    # Create an array of the desired eltype and size:
    v = UnalignedVector{Float64}(a)
    reshape(v, sz)
end
```

The key thing to note about this implementation is that we `mmap`ed
the buffer as a `Vector{UInt8}`; had we tried a `Vector{Float64}`,
more recent versions of Julia would have given us an error that would
look something like this:

```julia
ERROR: ArgumentError: unsafe_wrap: pointer 0x7f89817ae021 is not properly aligned to 8 bytes
Stacktrace:
 [1] #mmap#1(::Bool, ::Bool, ::Function, ::IOStream, ::Type{Array{Float64,2}}, ::Tuple{Int64,Int64}, ::Int64) at ./mmap.jl:139
 [2] mmap(::IOStream, ::Type{Array{Float64,2}}, ::Tuple{Int64,Int64}, ::Int64) at ./mmap.jl:102
 [3] reader(::IOStream) at ./REPL[4]:5
 [4] open(::##5#6, ::String) at ./iostream.jl:152
```

In contrast, since `UInt8` has an alignment of 1, it's always safe for `mmap`ping.

To create the array with desired element type, the
`UnalignedVector{Float64}(a)` call creates an
`AbstractVector{Float64}` out of the memory buffer, which we then
reshape to the desired size. If you want to try this, just read the file with

```julia
B = open("/tmp/testfile.bga") do io
    reader(io)
end
```

and you should see that `B == A`.
