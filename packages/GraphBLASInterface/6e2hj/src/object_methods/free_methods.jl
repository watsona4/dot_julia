"""
    GrB_free(object)

Generic method to free a GraphBLAS object.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> I = ZeroBasedIndex[0, 2, 4]; X = [10, 20, 30]; n = 3;

julia> GrB_Vector_new(w, GrB_INT64, 5)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_build(w, I, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w
nrows: 5 ncols: 1 max # entries: 3
format: standard CSC vlen: 5 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 3
column: 0 : 3 entries [0:2]
    row 0: int64 10
    row 2: int64 20
    row 4: int64 30


julia> GrB_free(w)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w NULL
```
"""
GrB_free(object::Abstract_GrB_Type) = GrB_Type_free(object)
GrB_free(object::Abstract_GrB_UnaryOp) = GrB_UnaryOp_free(object)
GrB_free(object::Abstract_GrB_BinaryOp) = GrB_BinaryOp_free(object)
GrB_free(object::Abstract_GrB_Monoid) = GrB_Monoid_free(object)
GrB_free(object::Abstract_GrB_Semiring) = GrB_Semiring_free(object)
GrB_free(object::Abstract_GrB_Vector) = GrB_Vector_free(object)
GrB_free(object::Abstract_GrB_Matrix) = GrB_Matrix_free(object)
GrB_free(object::Abstract_GrB_Descriptor) = GrB_Descriptor_free(object)

"""
    GrB_Type_free(unaryop)

Free GraphBLAS user-defined type.
"""
GrB_Type_free(type::Abstract_GrB_Type) = _NI("GrB_Type_free")

"""
    GrB_UnaryOp_free(unaryop)

Free unary operator.
"""
GrB_UnaryOp_free(unaryop::Abstract_GrB_UnaryOp) = _NI("GrB_UnaryOp_free")

"""
    GrB_BinaryOp_free(binaryop)

Free binary operator.
"""
GrB_BinaryOp_free(binaryop::Abstract_GrB_BinaryOp) = _NI("GrB_BinaryOp_free")

"""
    GrB_Monoid_free(monoid)

Free monoid.
"""
GrB_Monoid_free(monoid::Abstract_GrB_Monoid) = _NI("GrB_Monoid_free")

"""
    GrB_Semiring_free(semiring)

Free semiring.
"""
GrB_Semiring_free(semiring::Abstract_GrB_Semiring) = _NI("GrB_Semiring_free")

"""
    GrB_Vector_free(v)

Free vector.
"""
 GrB_Vector_free(v::Abstract_GrB_Vector) = _NI("GrB_Vector_free")

"""
    GrB_Matrix_free(A)

Free matrix.
"""
GrB_Matrix_free(A::Abstract_GrB_Matrix) = _NI("GrB_Matrix_free")

"""
    GrB_Descriptor_free(desc)

Free descriptor.
"""
GrB_Descriptor_free(desc::Abstract_GrB_Descriptor) = _NI("GrB_Descriptor_free")
