# Usage of resizable arrays

Instances of ResizableArray can be used as any other Julia multi-dimensional
arrays (sub-types of `AbstractArray`).  More specifically and like instances of
Julia `Array`, resizable arrays store their elements contiguously in
[column-major storage
order](https://en.wikipedia.org/wiki/Row-_and_column-major_order) and implement
fast linear-indexing, .  Resizable arrays should be as efficient as instances
of `Array` and can be used wherever an `Array` instance makes sense including
calls to external libraries via the `ccall` method.


## Creating a resizable array

An unitialized resizable array with elements of type `T` and dimensions `dims`
is created by:

```julia
ResizableArray{T}(undef, dims)
```

Dimensions may be a tuple of integers or a a list of integers.  The number `N`
of dimensions may be explicitly specified:

```julia
ResizableArray{T,N}(undef, dims)
```

For convenience, `ResizableVector{T}` and `ResizableMatrix{T}` are provided as
aliases to `ResizableArray{T,1}` and `ResizableArray{T,2}`.

Since a resizable array is *resizable* its dimensions may be specified at any
time (before using its contents).  An empty resizable array is simply created
by:

```julia
ResizableArray{T,N}()
```

The number of dimensions `N` must be specified in this case.  The
element type `T` and the number of dimensions `N` are part of the signature of
the type and cannot be changed without creating a new instance.

The `ResizableArray` constructor can be called to create a new resizable
array from an existing array `A` of any kind:

```julia
ResizableArray(A)
```

yields a resizable array of same size and element type as `A` and whose
contents is initially copied from that of `A`.

Element type `T` and number of dimensions `N` may be specified:

```julia
ResizableArray{T}(A)
ResizableArray{T,N}(A)
```

where `N` must match `ndims(A)` but `T` may be different from `eltype(A)`.

The `convert` method can be called to convert an existing array `A` of any kind
to a resizable array.  There are 3 possibilities:

```julia
convert(ResizableArray, A)
convert(ResizableArray{T}, A)
convert(ResizableArray{T,N}, A)
```

where `N` must match `ndims(A)` but `T` may be different from `eltype(A)`.
Unlike the `ResizableArray` constructor which always returns a new instance,
the `convert` method just returns its argument `A` if it is already a resizable
array whose type has the requested signature.  Otherwise, the `convert` method
behaves as the `ResizableArray` constructor.

The call `copy(ResizableArray,A)` yields a copy of `A` which is a resizable
array of same element type as `A`.  Call `copy(ResizableArray{T},A)` to specify
a possibly different the element type `T`.  The number of dimensions `N` may
also be specified but it must be the same as `A`:
`copy(ResizableArray{T,N},A)`.


## Resizing dimensions

The dimensions of a resizable array `A` may be changed by:

```julia
resize!(A, dims)
```

with `dims` the new dimensions.  The number of dimensions must remain unchanged
but the length of the array may change.  Depending on the type of the object
backing the storage of the array, it may be possible or not to augment the
number of elements of the array.  When array elements are stored in a regular
Julia vector, the number of element can always be augmented (unless too big to
fit in memory).  When such a resizable array is resized, its previous contents
is preserved if only the last dimension is changed.

Resizable arrays are designed to re-use storage if possible to avoid calling
the garbage collector.  This may be useful for real-time applications.  As a
consequence, the storage used by a resizable array `A` can only grow unless
`skrink!(A)` is called to reduce the storage to the minimum.


## Append or prepend contents

Calling:

```julia
append!(A, B) -> A
```

appends the elements of array `B` to a resizable array `A` and, as you may
guess, calling:

```julia
prepend!(A, B) -> A
```

inserts the elements of `B` before those of `A`.  Assuming `A` has `N`
dimensions, array `B` may have `N` or `N-1` dimensions.  The `N-1` first
dimensions of `B` must match the leading dimensions of `A`, these dimensions
are left unchanged in the result.  If `B` has the same number of dimensions as
`A`, the last dimension of the result is the sum of the last dimensions of `A`
and `B`; otherwise, the last dimension of the result is one plus the last
dimension of `A`.

The `grow!` method is able to either append or prepend the elements of an array
`B` to a resizable array `A`:

```julia
grow!(A, B, prepend=false) -> A
```

By default or if argument `prepend` is `false`, the elements of `B` are
inserted after those of `A`; otherwise, the elements of `B` are inserted before
those of `A`.

To improve performances of these operations, you can indicate the minimum
number of elements for a resizable array `A`:

```julia
sizehint!(A, len) -> A
```

The argument(s) after `A` may also be a list of dimensions:

```julia
sizehint!(A, dims) -> A
```

The method `maxlength(A)` yields the maximum number of elements that can be
stored in array `A` without resizing its internal buffer.


## Custom storage

The default storage of the elements of a resizable array is provided by a
regular Julia vector.  To use an object `buf` to store the elements of a
resizable array, use one of the following:

```julia
A = ResizableArray(buf, dims)
A = ResizableArray{T}(buf, dims)
A = ResizableArray{T,N}(buf, dims)
```

The buffer `buf` must store its elements contiguously using linear indexing
style with 1-based indices and have element type `T`, that is
`IndexStyle(typeof(buf))` and `eltype(buf)` must yield `IndexLinear()` and `T`
respectively.  The methods, `IndexStyle`, `eltype`, `length`, `getindex` and
`setindex!` must be applicable for the type of `buf`.  If the method `resize!`
is applicable for `buf`, the number of elements of `A` can be augmented;
otherwise the maximum number of elements of `A` is `length(buf)`.

!!! warning
    When explictely providing a resizable buffer `buf` for backing the
    storage of a resizable array `A`, you have the responsibility to make
    sure that the same buffer is not resized elsewhere.  Otherwise a
    segmentation fault may occur because `A` might assume a wrong buffer
    size.  To avoid this, the best is to make sure that only `A` owns `buf`
    and only `A` manages its size.  In the current implementation, the size
    of the internal buffer is never reduced so the same buffer may be
    safely shared by different resizable arrays.

When using the `convert` method or the `ResizableArray` constructor to convert
an array into a resizable array, the buffer for backing storage is always an
instance of `Vector{T}`.
