"""
    GrB_transpose(C, Mask, accum, A, desc)

Compute a new matrix that is the transpose of the source matrix.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> M = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(M, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 0]; J = ZeroBasedIndex[1, 2]; X = [10, 20]; n = 2;

julia> GrB_Matrix_build(M, I, J, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(M, GxB_COMPLETE)

GraphBLAS matrix: M 
nrows: 4 ncols: 4 max # entries: 2
format: standard CSR vlen: 4 nvec_nonempty: 1 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 2 
row: 0 : 2 entries [0:1]
    column 1: int64 10
    column 2: int64 20

julia> M_TRAN = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(M_TRAN, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_transpose(M_TRAN, GrB_NULL, GrB_NULL, M, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(M_TRAN, GxB_COMPLETE)

GraphBLAS matrix: M_TRAN 
nrows: 4 ncols: 4 max # entries: 2
format: standard CSR vlen: 4 nvec_nonempty: 2 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 2 
row: 1 : 1 entries [0:0]
    column 0: int64 10
row: 2 : 1 entries [1:1]
    column 0: int64 20
```
"""
GrB_transpose(                                  # C<Mask> = accum (C, A')
        C::Abstract_GrB_Matrix,                 # input/output matrix for results
        Mask::matrix_mask_type,                 # optional mask for C, unused if NULL
        accum::accum_type,                      # optional accum for Z=accum(C,T)
        A::Abstract_GrB_Matrix,                 # first input:  matrix A
        desc::desc_type                         # descriptor for C, Mask, and A
) = _NI("GrB_transpose")
