# EncodedArrays.jl

EncodedArray provides an API for arrays that store their elements in encoded/compressed form. This package is meant to be lightweight and only implements a simple codec `VarlenDiffArrayCodec`. As codec implementations are often complex and have various dependencies, more advanced codecs should
be implemented in separate packages.

Random access on an encoded array will typically be very inefficient, but linear access may be efficient (depending on the codec). Accessing the whole array contents at once, e.g. via `collect(A)`, `A[:]`, or copying/appending/conversion to a regular array, must be efficient.

An encoded array will typically have very inefficient random access, but may have efficient linear access and must be efficient when accessing the whole array contents at once via `getindex`, copying/appending to a regular array, etc.

This package defines two central abstract types, [`AbstractEncodedArray`](@ref) and [`AbstractArrayCodec`](@ref). It also defines a concrete type [`EncodedArray`](@ref) that implements most of the API and only leaves [`EncodedArrays.encode_data!`](@ref) and [`EncodedArrays.decode_data!`](@ref) for a new codec to implement.

Custom broadcasting optimizations are not implemented yet but will likely be added in the future.
