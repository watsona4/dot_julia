"""
    GrB_mxm(C, Mask, accum, semiring, A, B, desc)

Multiplies a matrix with another matrix on a semiring. The result is a matrix.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 2, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 1]; J1 = ZeroBasedIndex[0, 1]; X1 = [10, 20]; n1 = 2;

julia> GrB_Matrix_build(A, I1, J1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> B = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(B, GrB_INT64, 2, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1]; J2 = ZeroBasedIndex[0, 1]; X2 = [5, 15]; n2 = 2;

julia> GrB_Matrix_build(B, I2, J2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> C = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(C, GrB_INT64, 2, 2)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_mxm(C, GrB_NULL, GrB_NULL, GxB_PLUS_TIMES_INT64, A, B, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(C, GxB_COMPLETE)

GraphBLAS matrix: C 
nrows: 2 ncols: 2 max # entries: 2
format: standard CSR vlen: 2 nvec_nonempty: 2 nvec: 2 plen: 2 vdim: 2
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
last method used for GrB_mxm, vxm, or mxv: heap
number of entries: 2 
row: 0 : 1 entries [0:0]
    column 0: int64 50
row: 1 : 1 entries [1:1]
    column 1: int64 300
```
"""
GrB_mxm(                                    # C<Mask> = accum (C, A*B)
    C::Abstract_GrB_Matrix,                 # input/output matrix for results
    Mask::matrix_mask_type,                 # optional mask for C, unused if NULL
    accum::accum_type,                      # optional accum for Z=accum(C,T)
    semiring::Abstract_GrB_Semiring,        # defines '+' and '*' for A*B
    A::Abstract_GrB_Matrix,                 # first input:  matrix A
    B::Abstract_GrB_Matrix,                 # second input: matrix B
    desc::desc_type                         # descriptor for C, Mask, A, and B
) = _NI("GrB_mxm")

"""
    GrB_vxm(w, mask, accum, semiring, u, A, desc)

Multiplies a (row)vector with a matrix on an semiring. The result is a vector.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 2, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 1]; J1 = ZeroBasedIndex[0, 1]; X1 = [10, 20]; n1 = 2;

julia> GrB_Matrix_build(A, I1, J1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1]; X2 = [5, 6]; n2 = 2;

julia> GrB_Vector_build(u, I2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(w, GrB_INT64, 2)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_vxm(w, GrB_NULL, GrB_NULL, GxB_PLUS_TIMES_INT64, u, A, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w 
nrows: 2 ncols: 1 max # entries: 2
format: standard CSC vlen: 2 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
last method used for GrB_mxm, vxm, or mxv: heap
number of entries: 2 
column: 0 : 2 entries [0:1]
    row 0: int64 50
    row 1: int64 120
```
"""
GrB_vxm(                                    # w'<Mask> = accum (w, u'*A)
    w::Abstract_GrB_Vector,                 # input/output vector for results
    mask::vector_mask_type,                 # optional mask for w, unused if NULL
    accum::accum_type,                      # optional accum for z=accum(w,t)
    semiring::Abstract_GrB_Semiring,        # defines '+' and '*' for u'*A
    u::Abstract_GrB_Vector,                 # first input:  vector u
    A::Abstract_GrB_Matrix,                 # second input: matrix A
    desc::desc_type                         # descriptor for w, mask, and A
) = _NI("GrB_vxm")

"""
    GrB_mxv(w, mask, accum, semiring, A, u, desc)

Multiplies a matrix by a vector on a semiring. The result is a vector.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 2, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 0, 1]; J1 = ZeroBasedIndex[0, 1, 1]; X1 = [10, 20, 30]; n1 = 3;

julia> GrB_Matrix_build(A, I1, J1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 2)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1]; X2 = [5, 6]; n2 = 2;

julia> GrB_Vector_build(u, I2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(w, GrB_INT64, 2)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_mxv(w, GrB_NULL, GrB_NULL, GxB_PLUS_TIMES_INT64, A, u, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w 
nrows: 2 ncols: 1 max # entries: 2
format: standard CSC vlen: 2 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
last method used for GrB_mxm, vxm, or mxv: dot
number of entries: 2 
column: 0 : 2 entries [0:1]
    row 0: int64 170
    row 1: int64 180
```
"""
GrB_mxv(                                    # w<Mask> = accum (w, A*u)
    w::Abstract_GrB_Vector,                 # input/output vector for results
    mask::vector_mask_type,                 # optional mask for w, unused if NULL
    accum::accum_type,                      # optional accum for z=accum(w,t)
    semiring::Abstract_GrB_Semiring,        # defines '+' and '*' for A*B
    A::Abstract_GrB_Matrix,                 # first input:  matrix A
    u::Abstract_GrB_Vector,                 # second input: vector u
    desc::desc_type                         # descriptor for w, mask, and A
) = _NI("GrB_mxv")
