"""
    GrB_assign(arg1, Mask, accum, arg4, arg5, ...)

Generic method for submatrix/subvector assignment.
"""
GrB_assign(w::Abstract_GrB_Vector, mask, accum, u::Abstract_GrB_Vector, I, ni, desc ) = GrB_Vector_assign(w, mask, accum, u, I, ni, desc)
GrB_assign(w::Abstract_GrB_Vector, mask, accum, x, I, ni, desc) = GrB_Vector_assign(w, mask, accum, x, I, ni, desc )
GrB_assign(C::Abstract_GrB_Matrix, Mask, accum, A::Abstract_GrB_Matrix, I, ni, J, nj, desc) = GrB_Matrix_assign(C, Mask, accum, A, I, ni, J, nj, desc)
GrB_assign(C::Abstract_GrB_Matrix, Mask, accum, u::Abstract_GrB_Vector, I, ni, j, desc) = GrB_Col_assign(C, Mask, accum, u, I, ni, j, desc)
GrB_assign(C::Abstract_GrB_Matrix, Mask, accum, u::Abstract_GrB_Vector, i::Abstract_GrB_Index, J, nj, desc) = GrB_Row_assign(C, Mask, accum, u, i, J, nj, desc)
GrB_assign(C::Abstract_GrB_Matrix, Mask, accum, x, I, ni, J, nj, desc) = GrB_Matrix_assign(C, Mask, accum, x, I, ni, J, nj, desc)

"""
    GrB_Vector_assign(w, mask, accum, u, I, ni, desc)

Assign values from one GraphBLAS vector to a subset of a vector as specified by a set of
indices. The size of the input vector is the same size as the index array provided.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(w, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 1]; X = [10, 20]; n = 2;

julia> GrB_Vector_build(u, I, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_assign(w, GrB_NULL, GrB_NULL, u, [2, 4], 2, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractTuples(w)
(ZeroBasedIndex[ZeroBasedIndex(0x0000000000000002), ZeroBasedIndex(0x0000000000000004)], [10, 20])
```
"""
GrB_Vector_assign(                                  # w<mask>(I) = accum (w(I),u)
        w::Abstract_GrB_Vector,                     # input/output matrix for results
        mask::vector_mask_type,                     # optional mask for w, unused if NULL
        accum::accum_type,                          # optional accum for z=accum(w(I),t)
        u::Abstract_GrB_Vector,                     # first input:  vector u
        I::indices_type,                            # row indices
        ni::Union{Int64, UInt64},                   # number of row indices
        desc::desc_type                             # descriptor for w and mask
) = _NI("GrB_Vector_assign")

"""
    GrB_Matrix_assign(C, Mask, accum, A, I, ni, J, nj, desc)

Assign values from one GraphBLAS matrix to a subset of a matrix as specified by a set of
indices. The dimensions of the input matrix are the same size as the row and column index arrays provided.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 0, 2, 2]; J = ZeroBasedIndex[1, 2, 0, 2]; X = [10, 20, 30, 40]; n = 4;

julia> GrB_Matrix_build(A, I, J, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> C = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(C, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_assign(C, GrB_NULL, GrB_NULL, A, GrB_ALL, 4, GrB_ALL, 4, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_wait()
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Matrix_fprint(C, GxB_COMPLETE)

GraphBLAS matrix: C
nrows: 4 ncols: 4 max # entries: 4
format: standard CSR vlen: 4 nvec_nonempty: 2 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 4
row: 0 : 2 entries [0:1]
    column 1: int64 10
    column 2: int64 20
row: 2 : 2 entries [2:3]
    column 0: int64 30
    column 2: int64 40
```
"""
GrB_Matrix_assign(                                  # C<Mask>(I,J) = accum (C(I,J),A)
        C::Abstract_GrB_Matrix,                     # input/output matrix for results
        Mask::matrix_mask_type,                     # optional mask for C, unused if NULL
        accum::accum_type,                          # optional accum for Z=accum(C(I,J),T)
        A::Abstract_GrB_Matrix,                     # first input:  matrix A
        I::indices_type,                            # row indices
        ni::Union{Int64, UInt64},                   # number of row indices
        J::indices_type,                            # column indices
        nj::Union{Int64, UInt64},                   # number of column indices
        desc::desc_type                             # descriptor for C, Mask, and A
) = _NI("GrB_Matrix_assign")

"""
    GrB_Col_assign(C, Mask, accum, u, I, ni, j, desc)

Assign the contents of a vector to a subset of elements in one column of a matrix.
Note that since the output cannot be transposed, a different variant of assign is provided
to assign to a row of matrix.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 0, 2, 2]; J = ZeroBasedIndex[1, 2, 0, 2]; X = [10, 20, 30, 40]; n = 4;

julia> GrB_Matrix_build(A, I, J, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1]; X2 = [5, 6]; n2 = 2;

julia> GrB_Vector_build(u, I2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Col_assign(A, GrB_NULL, GrB_NULL, u, ZeroBasedIndex[1, 2], 2, ZeroBasedIndex(0), GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_wait()
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Matrix_fprint(A, GxB_COMPLETE)

GraphBLAS matrix: A
nrows: 4 ncols: 4 max # entries: 7
format: standard CSR vlen: 4 nvec_nonempty: 3 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 5
row: 0 : 2 entries [0:1]
    column 1: int64 10
    column 2: int64 20
row: 1 : 1 entries [2:2]
    column 0: int64 5
row: 2 : 2 entries [3:4]
    column 0: int64 6
    column 2: int64 40
```
"""
GrB_Col_assign(                                     # C<mask>(I,j) = accum (C(I,j),u)
        C::Abstract_GrB_Matrix,                     # input/output matrix for results
        mask::vector_mask_type,                     # optional mask for C(:,j), unused if NULL
        accum::accum_type,                          # optional accum for z=accum(C(I,j),t)
        u::Abstract_GrB_Vector,                     # input vector
        I::indices_type,                            # row indices
        ni::Union{Int64, UInt64},                   # number of row indices
        j::Abstract_GrB_Index,                      # column index
        desc::desc_type                             # descriptor for C(:,j) and mask
) = _NI("GrB_Col_assign")

"""
    GrB_Row_assign(C, mask, accum, u, i, J, nj, desc)

Assign the contents of a vector to a subset of elements in one row of a matrix.
Note that since the output cannot be transposed, a different variant of assign is provided
to assign to a column of a matrix.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 0, 2, 2]; J = ZeroBasedIndex[1, 2, 0, 2]; X = [10, 20, 30, 40]; n = 4;

julia> GrB_Matrix_build(A, I, J, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1]; X2 = [5, 6]; n2 = 2;

julia> GrB_Vector_build(u, I2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Row_assign(A, GrB_NULL, GrB_NULL, u, ZeroBasedIndex(0), ZeroBasedIndex[1, 3], 2, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_wait()
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Matrix_fprint(A, GxB_COMPLETE)

GraphBLAS matrix: A
nrows: 4 ncols: 4 max # entries: 7
format: standard CSR vlen: 4 nvec_nonempty: 2 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 5
row: 0 : 3 entries [0:2]
    column 1: int64 5
    column 2: int64 20
    column 3: int64 6
row: 2 : 2 entries [3:4]
    column 0: int64 30
    column 2: int64 40
```
"""
GrB_Row_assign(                                     # C<mask'>(i,J) = accum (C(i,J),u')
        C::Abstract_GrB_Matrix,                     # input/output matrix for results
        mask::vector_mask_type,                     # optional mask for C(i,:), unused if NULL
        accum::accum_type,                          # optional accum for z=accum(C(i,J),t)
        u::Abstract_GrB_Vector,                     # input vector
        i::Abstract_GrB_Index,                      # row index
        J::indices_type,                            # column indices
        nj::Union{Int64, UInt64},                   # number of column indices
        desc::desc_type                             # descriptor for C(i,:) and mask
) = _NI("GrB_Row_assign")

"""
    GrB_Vector_assign(w, mask, accum, x, I, ni, desc)

Assign the same value to a specified subset of vector elements.
With the use of `GrB_ALL`, the entire destination vector can be filled with the constant.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(w, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_assign(w, GrB_NULL, GrB_NULL, 2.3, ZeroBasedIndex[0, 3], 2, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_extractTuples(w)
(ZeroBasedIndex[ZeroBasedIndex(0x0000000000000000), ZeroBasedIndex(0x0000000000000003)], [2.3, 2.3])
```
"""
GrB_Vector_assign(                                  # w<mask>(I) = accum (w(I),x)
        w::Abstract_GrB_Vector,                     # input/output vector for results
        mask::vector_mask_type,                     # optional mask for w, unused if NULL
        accum::accum_type,                          # optional accum for Z=accum(w(I),x)
        x,                                          # scalar to assign to w(I)
        I::indices_type,                            # row indices
        ni::Union{Int64, UInt64},                   # number of row indices
        desc::desc_type                             # descriptor for w and mask
) = _NI("GrB_Vector_assign")

"""
    GrB_Matrix_assign(C, Mask, accum, x, I, ni, J, nj, desc)

Assign the same value to a specified subset of matrix elements.
With the use of `GrB_ALL`, the entire destination matrix can be filled with the constant.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Bool}()
GrB_Matrix{Bool}

julia> GrB_Matrix_new(A, GrB_BOOL, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Matrix_assign(A, GrB_NULL, GrB_NULL, true, ZeroBasedIndex[0, 1], 2, ZeroBasedIndex[0, 1], 2, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_wait()
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Matrix_fprint(A, GxB_COMPLETE)

GraphBLAS matrix: A
nrows: 4 ncols: 4 max # entries: 4
format: standard CSR vlen: 4 nvec_nonempty: 2 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  bool size: 1
number of entries: 4
row: 0 : 2 entries [0:1]
    column 0: bool 1
    column 1: bool 1
row: 1 : 2 entries [2:3]
    column 0: bool 1
    column 1: bool 1
```
"""
GrB_Matrix_assign(                                  # C<Mask>(I,J) = accum (C(I,J),x)
        C::Abstract_GrB_Matrix,                     # input/output matrix for results
        Mask::matrix_mask_type,                     # optional mask for C, unused if NULL
        accum::accum_type,                          # optional accum for Z=accum(C(I,J),x)
        x,                                          # scalar to assign to C(I,J)
        I::indices_type,                            # row indices
        ni::Union{Int64, UInt64},                   # number of row indices
        J::indices_type,                            # column indices
        nj::Union{Int64, UInt64},                   # number of column indices
        desc::desc_type                             # descriptor for C and Mask
) = _NI("GrB_Matrix_assign")
