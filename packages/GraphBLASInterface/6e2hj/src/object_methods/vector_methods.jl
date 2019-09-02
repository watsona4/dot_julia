"""
    GrB_Vector_new(v, type, n)

Initialize a vector with specified domain and size.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(V, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0
```
"""
GrB_Vector_new(
    v::Abstract_GrB_Vector,
    type::Abstract_GrB_Type,
    n::Union{Int64, UInt64}) = _NI("GrB_Vector_new")

"""
    GrB_Vector_dup(w, u)

Initialize a vector with the same domain, size, and contents as another vector.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(V, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 4]; X = [2, 32, 4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> B = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_dup(B, V)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Vector_fprint(B, GxB_COMPLETE)

GraphBLAS vector: B
nrows: 5 ncols: 1 max # entries: 3
format: standard CSC vlen: 5 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 3
column: 0 : 3 entries [0:2]
    row 1: int64 2
    row 2: int64 32
    row 4: int64 4
```
"""
GrB_Vector_dup(w::Abstract_GrB_Vector, u::Abstract_GrB_Vector) = _NI("GrB_Vector_dup")

"""
    GrB_Vector_clear(v)

Remove all the elements (tuples) from a vector.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(V, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 4]; X = [2, 32, 4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractTuples(V)
(ZeroBasedIndex[ZeroBasedIndex(0x0000000000000001), ZeroBasedIndex(0x0000000000000002), ZeroBasedIndex(0x0000000000000004)], [2, 32, 4])

julia> GrB_Vector_clear(V)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractTuples(V)
(ZeroBasedIndex[], Int64[])
```
"""
GrB_Vector_clear(v::Abstract_GrB_Vector) = _NI("GrB_Vector_clear")

"""
    GrB_Vector_size(v)

Return the size of a vector if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(V, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_size(V)
0x0000000000000004
```
"""
GrB_Vector_size(v::Abstract_GrB_Vector) = _NI("GrB_Vector_size")

"""
    GrB_Vector_nvals(v)

Return the number of stored elements in a vector if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(V, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = [0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_nvals(V)
0x0000000000000003
```
"""
GrB_Vector_nvals(v::Abstract_GrB_Vector) = _NI("GrB_Vector_nvals")

"""
    GrB_Vector_build(w, I, X, nvals, dup)

Store elements from tuples into a vector.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(V, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Vector_fprint(V, GxB_COMPLETE)

GraphBLAS vector: V
nrows: 4 ncols: 1 max # entries: 3
format: standard CSC vlen: 4 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  double size: 8
number of entries: 3
column: 0 : 3 entries [0:2]
    row 0: double 2.1
    row 2: double 3.2
    row 3: double 4.4
```
"""
GrB_Vector_build(
    w::Abstract_GrB_Vector,
    I::Vector{U},
    X::Vector,
    nvals::Union{Int64, UInt64},
    dup::Abstract_GrB_BinaryOp) where U <: Abstract_GrB_Index = _NI("GrB_Vector_build")

"""
    GrB_Vector_setElement(w, x, i)

Set one element of a vector to a given value, w[i] = x.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(V, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 4]; X = [2, 32, 4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractElement(V, ZeroBasedIndex(2))
32

julia> GrB_Vector_setElement(V, 7, ZeroBasedIndex(2))
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractElement(V, ZeroBasedIndex(2))
7
```
"""
GrB_Vector_setElement(
    w::Abstract_GrB_Vector,
    x,
    i::Abstract_GrB_Index) = _NI("GrB_Vector_setElement")

"""
    GrB_Vector_extractElement(v, i)

Return element of a vector at a given index (v[i]) if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(V, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractElement(V, ZeroBasedIndex(2))
3.2
```
"""
GrB_Vector_extractElement(v::Abstract_GrB_Vector, i::Abstract_GrB_Index) = _NI("GrB_Vector_extractElement")

"""
    GrB_Vector_extractTuples(v, index_type)

Return tuples stored in a vector if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(V, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;

julia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractTuples(V)
(ZeroBasedIndex[ZeroBasedIndex(0x0000000000000000), ZeroBasedIndex(0x0000000000000002), ZeroBasedIndex(0x0000000000000003)], [2.1, 3.2, 4.4])
```
"""
GrB_Vector_extractTuples(v::Abstract_GrB_Vector, index_type::Type{<:Abstract_GrB_Index}) = _NI("GrB_Vector_extractTuples")
