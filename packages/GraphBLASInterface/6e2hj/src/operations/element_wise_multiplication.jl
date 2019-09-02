"""
    GrB_eWiseMult(C, mask, accum, op, A, B, desc)

Generic method for element-wise matrix and vector operations: using set intersection.

`GrB_eWiseMult` computes `C<Mask> = accum (C, A .* B)`, where pairs of elements in two matrices (or vectors) are
pairwise "multiplied" with C(i, j) = mult (A(i, j), B(i, j)). The "multiplication" operator can be any binary operator.
The pattern of the result T = A .* B is the set intersection (not union) of A and B. Entries outside of the intersection
are not computed. This is primary difference with `GrB_eWiseAdd`. The input matrices A and/or B may be transposed first,
via the descriptor. For a semiring, the mult operator is the semiring's multiply operator; this differs from the
eWiseAdd methods which use the semiring's add operator instead.
"""
GrB_eWiseMult(C, mask, accum, op::Abstract_GrB_BinaryOp, A::Abstract_GrB_Vector, B, desc) = GrB_eWiseMult_Vector_BinaryOp(C, mask, accum, op, A, B, desc)
GrB_eWiseMult(C, mask, accum, op::Abstract_GrB_Monoid, A::Abstract_GrB_Vector, B, desc) = GrB_eWiseMult_Vector_Monoid(C, mask, accum, op, A, B, desc)
GrB_eWiseMult(C, mask, accum, op::Abstract_GrB_Semiring, A::Abstract_GrB_Vector, B, desc) = GrB_eWiseMult_Vector_Semiring(C, mask, accum, op, A, B, desc)
GrB_eWiseMult(C, mask, accum, op::Abstract_GrB_BinaryOp, A::Abstract_GrB_Matrix, B, desc) = GrB_eWiseMult_Matrix_BinaryOp(C, mask, accum, op, A, B, desc)
GrB_eWiseMult(C, mask, accum, op::Abstract_GrB_Monoid, A::Abstract_GrB_Matrix, B, desc) = GrB_eWiseMult_Matrix_Monoid(C, mask, accum, op, A, B, desc)
GrB_eWiseMult(C, mask, accum, op::Abstract_GrB_Semiring, A::Abstract_GrB_Matrix, B, desc) = GrB_eWiseMult_Matrix_Semiring(C, mask, accum, op, A, B, desc)

"""
    GrB_eWiseMult_Vector_Semiring(w, mask, accum, semiring, u, v, desc)

Compute element-wise vector multiplication using semiring. Semiring's multiply operator is used.
`w<mask> = accum (w, u .* v)`

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 2, 4]; X1 = [10, 20, 3]; n1 = 3;

julia> GrB_Vector_build(u, I1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> v = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(v, GrB_FP64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1, 4]; X2 = [1.1, 2.2, 3.3]; n2 = 3;

julia> GrB_Vector_build(v, I2, X2, n2, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(w, GrB_FP64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_eWiseMult_Vector_Semiring(w, GrB_NULL, GrB_NULL, GxB_PLUS_TIMES_FP64, u, v, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w 
nrows: 5 ncols: 1 max # entries: 2
format: standard CSC vlen: 5 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  double size: 8
number of entries: 2 
column: 0 : 2 entries [0:1]
    row 0: double 11
    row 4: double 9.9
```
"""
GrB_eWiseMult_Vector_Semiring(                  # w<Mask> = accum (w, u.*v)
    w::Abstract_GrB_Vector,                     # input/output vector for results
    mask::vector_mask_type,                     # optional mask for w, unused if NULL
    accum::accum_type,                          # optional accum for z=accum(w,t)
    semiring::Abstract_GrB_Semiring,            # defines '.*' for t=u.*v
    u::Abstract_GrB_Vector,                     # first input:  vector u
    v::Abstract_GrB_Vector,                     # second input: vector v
    desc::desc_type                             # descriptor for w and mask
) = _NI("GrB_eWiseMult_Vector_Semiring")

"""
    GrB_eWiseMult_Vector_Monoid(w, mask, accum, monoid, u, v, desc)

Compute element-wise vector multiplication using monoid.
`w<mask> = accum (w, u .* v)`

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 2, 4]; X1 = [10, 20, 3]; n1 = 3;

julia> GrB_Vector_build(u, I1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> v = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(v, GrB_FP64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1, 4]; X2 = [1.1, 2.2, 3.3]; n2 = 3;

julia> GrB_Vector_build(v, I2, X2, n2, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(w, GrB_FP64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_eWiseMult_Vector_Monoid(w, GrB_NULL, GrB_NULL, GxB_MAX_FP64_MONOID, u, v, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w 
nrows: 5 ncols: 1 max # entries: 2
format: standard CSC vlen: 5 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  double size: 8
number of entries: 2 
column: 0 : 2 entries [0:1]
    row 0: double 10
    row 4: double 3.3
```
"""
GrB_eWiseMult_Vector_Monoid(                    # w<Mask> = accum (w, u.*v)
    w::Abstract_GrB_Vector,                     # input/output vector for results
    mask::vector_mask_type,                     # optional mask for w, unused if NULL
    accum::accum_type,                          # optional accum for z=accum(w,t)
    monoid::Abstract_GrB_Monoid,                # defines '.*' for t=u.*v
    u::Abstract_GrB_Vector,                     # first input:  vector u
    v::Abstract_GrB_Vector,                     # second input: vector v
    desc::desc_type                             # descriptor for w and mask
) = _NI("GrB_eWiseMult_Vector_Monoid")

"""
    GrB_eWiseMult_Vector_BinaryOp(w, mask, accum, mult, u, v, desc)

Compute element-wise vector multiplication using binary operator.
`w<mask> = accum (w, u .* v)`

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 2, 4]; X1 = [10, 20, 30]; n1 = 3;

julia> GrB_Vector_build(u, I1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> v = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(v, GrB_FP64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 1, 4]; X2 = [1.1, 2.2, 3.3]; n2 = 3;

julia> GrB_Vector_build(v, I2, X2, n2, GrB_FIRST_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(w, GrB_FP64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_eWiseMult_Vector_BinaryOp(w, GrB_NULL, GrB_NULL, GrB_TIMES_FP64, u, v, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w 
nrows: 5 ncols: 1 max # entries: 2
format: standard CSC vlen: 5 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  double size: 8
number of entries: 2 
column: 0 : 2 entries [0:1]
    row 0: double 11
    row 4: double 99
```
"""
GrB_eWiseMult_Vector_BinaryOp(                  # w<Mask> = accum (w, u.*v)
    w::Abstract_GrB_Vector,                     # input/output vector for results
    mask::vector_mask_type,                     # optional mask for w, unused if NULL
    accum::accum_type,                          # optional accum for z=accum(w,t)
    mult::Abstract_GrB_BinaryOp,                # defines '.*' for t=u.*v
    u::Abstract_GrB_Vector,                     # first input:  vector u
    v::Abstract_GrB_Vector,                     # second input: vector v
    desc::desc_type                             # descriptor for w and mask
) = _NI("GrB_eWiseMult_Vector_BinaryOp")

"""
    GrB_eWiseMult_Matrix_Semiring(C, Mask, accum, semiring, A, B, desc)

Compute element-wise matrix multiplication using semiring. Semiring's multiply operator is used.
`C<Mask> = accum (C, A .* B)`

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 0, 2, 2]; J1 = ZeroBasedIndex[1, 2, 0, 2]; X1 = [10, 20, 30, 40]; n1 = 4;

julia> GrB_Matrix_build(A, I1, J1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> B = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(B, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 0, 2]; J2 = ZeroBasedIndex[3, 2, 0]; X2 = [15, 16, 17]; n2 = 3;

julia> GrB_Matrix_build(B, I2, J2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> C = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(C, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_eWiseMult_Matrix_Semiring(C, GrB_NULL, GrB_NULL, GxB_PLUS_TIMES_INT64, A, B, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(C, GxB_COMPLETE)

GraphBLAS matrix: C 
nrows: 4 ncols: 4 max # entries: 2
format: standard CSR vlen: 4 nvec_nonempty: 2 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 2 
row: 0 : 1 entries [0:0]
    column 2: int64 320
row: 2 : 1 entries [1:1]
    column 0: int64 510
```
"""
GrB_eWiseMult_Matrix_Semiring(                  # C<Mask> = accum (C, A.*B)
    C::Abstract_GrB_Matrix,                     # input/output matrix for results
    Mask::matrix_mask_type,                     # optional mask for C, unused if NULL
    accum::accum_type,                          # optional accum for Z=accum(C,T)
    semiring::Abstract_GrB_Semiring,            # defines '.*' for T=A.*B
    A::Abstract_GrB_Matrix,                     # first input:  matrix A
    B::Abstract_GrB_Matrix,                     # second input: matrix B
    desc::desc_type                             # descriptor for C, Mask, A, and B
) = _NI("GrB_eWiseMult_Matrix_Semiring")

"""
    GrB_eWiseMult_Matrix_Monoid(C, Mask, accum, monoid, A, B, desc)

Compute element-wise matrix multiplication using monoid.
`C<Mask> = accum (C, A .* B)`

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 0, 2, 2]; J1 = ZeroBasedIndex[1, 2, 0, 2]; X1 = [10, 20, 30, 40]; n1 = 4;

julia> GrB_Matrix_build(A, I1, J1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> B = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(B, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 0, 2]; J2 = ZeroBasedIndex[3, 2, 0]; X2 = [15, 16, 17]; n2 = 3;

julia> GrB_Matrix_build(B, I2, J2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> C = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(C, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_eWiseMult_Matrix_Monoid(C, GrB_NULL, GrB_NULL, GxB_PLUS_INT64_MONOID, A, B, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(C, GxB_COMPLETE)

GraphBLAS matrix: C 
nrows: 4 ncols: 4 max # entries: 2
format: standard CSR vlen: 4 nvec_nonempty: 2 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 2 
row: 0 : 1 entries [0:0]
    column 2: int64 36
row: 2 : 1 entries [1:1]
    column 0: int64 47
```
"""
GrB_eWiseMult_Matrix_Monoid(                    # C<Mask> = accum (C, A.*B)
    C::Abstract_GrB_Matrix,                     # input/output matrix for results
    Mask::matrix_mask_type,                     # optional mask for C, unused if NULL
    accum::accum_type,                          # optional accum for Z=accum(C,T)
    monoid::Abstract_GrB_Monoid,                # defines '.*' for T=A.*B
    A::Abstract_GrB_Matrix,                     # first input:  matrix A
    B::Abstract_GrB_Matrix,                     # second input: matrix B
    desc::desc_type                             # descriptor for C, Mask, A, and B
) = _NI("GrB_eWiseMult_Matrix_Monoid")

"""
    GrB_eWiseMult_Matrix_BinaryOp(C, Mask, accum, mult, A, B, desc)

Compute element-wise matrix multiplication using binary operator.
`C<Mask> = accum (C, A .* B)`

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> A = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(A, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I1 = ZeroBasedIndex[0, 0, 2, 2]; J1 = ZeroBasedIndex[1, 2, 0, 2]; X1 = [10, 20, 30, 40]; n1 = 4;

julia> GrB_Matrix_build(A, I1, J1, X1, n1, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> B = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(B, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I2 = ZeroBasedIndex[0, 0, 2]; J2 = ZeroBasedIndex[3, 2, 0]; X2 = [15, 16, 17]; n2 = 3;

julia> GrB_Matrix_build(B, I2, J2, X2, n2, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> C = GrB_Matrix{Int64}()
GrB_Matrix{Int64}

julia> GrB_Matrix_new(C, GrB_INT64, 4, 4)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_eWiseMult_Matrix_BinaryOp(C, GrB_NULL, GrB_NULL, GrB_PLUS_INT64, A, B, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(C, GxB_COMPLETE)

GraphBLAS matrix: C 
nrows: 4 ncols: 4 max # entries: 2
format: standard CSR vlen: 4 nvec_nonempty: 2 nvec: 4 plen: 4 vdim: 4
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 2 
row: 0 : 1 entries [0:0]
    column 2: int64 36
row: 2 : 1 entries [1:1]
    column 0: int64 47
```
"""
GrB_eWiseMult_Matrix_BinaryOp(                  # C<Mask> = accum (C, A.*B)
    C::Abstract_GrB_Matrix,                     # input/output matrix for results
    Mask::matrix_mask_type,                     # optional mask for C, unused if NULL
    accum::accum_type,                          # optional accum for Z=accum(C,T)
    mult::Abstract_GrB_BinaryOp,                # defines '.*' for T=A.*B
    A::Abstract_GrB_Matrix,                     # first input:  matrix A
    B::Abstract_GrB_Matrix,                     # second input: matrix B
    desc::desc_type                             # descriptor for C, Mask, A, and B
) = _NI("GrB_eWiseMult_Matrix_BinaryOp")
