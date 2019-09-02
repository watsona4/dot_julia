"""
    GrB_Matrix_new(A, type, nrows, ncols)

Initialize a matrix with specified domain and dimensions.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0
```
"""
GrB_Matrix_new(
    A::Abstract_GrB_Matrix,
    type::Abstract_GrB_Type,
    nrows::Union{Int64, UInt64},
    ncols::Union{Int64, UInt64}) = _NI("GrB_Matrix_new")

"""
    GrB_Matrix_build(C, I, J, X, nvals, dup)

Store elements from tuples into a matrix.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 2, 2, 3]; J = ZeroBasedIndex[1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;

julia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Matrix_fprint(MAT, GxB_COMPLETE)

GraphBLAS matrix: MAT
nrows: 4 ncols: 4 max # entries: 5
format: standard CSR vlen: 4 nvec_nonempty: 3 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int8_t size: 1
number of entries: 5
row: 1 : 1 entries [0:0]
    column 1: int8 2
row: 2 : 3 entries [1:3]
    column 1: int8 4
    column 2: int8 3
    column 3: int8 5
row: 3 : 1 entries [4:4]
    column 3: int8 6
```
"""
GrB_Matrix_build(
    C::Abstract_GrB_Matrix,
    I::Vector{U},
    J::Vector{U},
    X::Vector,
    nvals::Union{Int64, UInt64},
    dup::Abstract_GrB_BinaryOp) where {U <: Abstract_GrB_Index} = _NI("GrB_Matrix_build")

"""
    GrB_Matrix_nrows(A)

Return the number of rows in a matrix if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_nrows(MAT)
0x0000000000000004
```
"""
GrB_Matrix_nrows(A::Abstract_GrB_Matrix) = _NI("GrB_Matrix_nrows")

"""
    GrB_Matrix_ncols(A)

Return the number of columns in a matrix if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_ncols(MAT)
0x0000000000000004
```
"""
GrB_Matrix_ncols(A::Abstract_GrB_Matrix) = _NI("GrB_Matrix_ncols")

"""
    GrB_Matrix_nvals(A)

Return the number of stored elements in a matrix if successful.
Else return `GrB_Info` error code..

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = [ZeroBasedIndex1, 2, 2, 2, 3]; J = ZeroBasedIndex[1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;

julia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_nvals(MAT)
0x0000000000000005
```
"""
GrB_Matrix_nvals(A::Abstract_GrB_Matrix) = _NI("GrB_Matrix_nvals")

"""
    GrB_Matrix_dup(C, A)

Initialize a new matrix with the same domain, dimensions, and contents as another matrix.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 2, 2, 3]; J = ZeroBasedIndex[1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;

julia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)
GrB_SUCCESS::GrB_Info = 0

julia> B = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_dup(B, MAT)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Matrix_fprint(B, GxB_COMPLETE)

GraphBLAS matrix: B
nrows: 4 ncols: 4 max # entries: 5
format: standard CSR vlen: 4 nvec_nonempty: 3 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int8_t size: 1
number of entries: 5
row: 1 : 1 entries [0:0]
    column 1: int8 2
row: 2 : 3 entries [1:3]
    column 1: int8 4
    column 2: int8 3
    column 3: int8 5
row: 3 : 1 entries [4:4]
    column 3: int8 6
```
"""
GrB_Matrix_dup(C::Abstract_GrB_Matrix, A::Abstract_GrB_Matrix) = _NI("GrB_Matrix_dup")

"""
    GrB_Matrix_clear(A)

Remove all elements from a matrix.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 2, 2, 3]; J = ZeroBasedIndex[1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;

julia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_nvals(MAT)
0x0000000000000005

julia> GrB_Matrix_clear(MAT)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_nvals(MAT)
0x0000000000000000
```
"""
GrB_Matrix_clear(A::Abstract_GrB_Matrix) = _NI("GrB_Matrix_clear")

"""
    GrB_Matrix_setElement(C, X, I, J)

Set one element of a matrix to a given value, C[I][J] = X.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 2, 2, 3]; J = ZeroBasedIndex[1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;

julia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_extractElement(MAT, ZeroBasedIndex(1), ZeroBasedIndex(1))
2

julia> GrB_Matrix_setElement(MAT, Int8(7), ZeroBasedIndex(1), ZeroBasedIndex(1))
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_extractElement(MAT, ZeroBasedIndex(1), ZeroBasedIndex(1))
7
```
"""
GrB_Matrix_setElement(
    C::Abstract_GrB_Matrix,
    X,
    I::Abstract_GrB_Index,
    J::Abstract_GrB_Index) = _NI("GrB_Matrix_setElement")

"""
    GrB_Matrix_extractElement(A, row_index, col_index)

Return element of a matrix at a given index (A[row_index][col_index]) if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 2, 2, 3]; J = ZeroBasedIndex[1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;

julia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_extractElement(MAT, ZeroBasedIndex(1), ZeroBasedIndex(1))
2
```
"""
GrB_Matrix_extractElement(
    A::Abstract_GrB_Matrix,
    row_index::Abstract_GrB_Index,
    col_index::Abstract_GrB_Index) = _NI("GrB_Matrix_extractElement")

"""
    GrB_Matrix_extractTuples(A, index_type)

Return tuples stored in a matrix if successful.
Else return `GrB_Info` error code.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> MAT = GrB_Matrix{Int8}()
GrB_Matrix{Int8}

julia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[1, 2, 2, 2, 3]; J = ZeroBasedIndex[1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;

julia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_extractTuples(MAT)
(ZeroBasedIndex[ZeroBasedIndex(0x0000000000000001), ZeroBasedIndex(0x0000000000000002), ZeroBasedIndex(0x0000000000000002), ZeroBasedIndex(0x0000000000000002), ZeroBasedIndex(0x0000000000000003)], ZeroBasedIndex[ZeroBasedIndex(0x0000000000000001), ZeroBasedIndex(0x0000000000000001), ZeroBasedIndex(0x0000000000000002), ZeroBasedIndex(0x0000000000000003), ZeroBasedIndex(0x0000000000000003)], Int8[2, 4, 3, 5, 6])
```
"""
GrB_Matrix_extractTuples(A::Abstract_GrB_Matrix, index_type::Type{<:Abstract_GrB_Index}) = _NI("GrB_Matrix_extractTuples")
