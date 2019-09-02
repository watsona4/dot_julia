"""
    GrB_Type_new(type, sizeof_type)

Initialize a GraphBLAS type with its size.
"""
GrB_Type_new(type::Abstract_GrB_Type, sizeof_type::UInt) = _NI("GrB_Type_new")

"""
    GrB_UnaryOp_new(op, fn, ztype, xtype)

Initialize a GraphBLAS unary operator with a specified user-defined function and its types.
The function should take a single value(x) & return an output(z), f(x) = z.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> u = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(u, GrB_INT64, 3)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 2]; X = [10, 20]; n = 2;

julia> GrB_Vector_build(u, I, X, n, GrB_FIRST_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> w = GrB_Vector{Int64}()
GrB_Vector{Int64}

julia> GrB_Vector_new(w, GrB_INT64, 3)
GrB_SUCCESS::GrB_Info = 0

julia> function NEG(a)
           return -a
       end
NEG (generic function with 1 method)

julia> negative = GrB_UnaryOp()
GrB_UnaryOp

julia> GrB_UnaryOp_new(negative, NEG, GrB_INT64, GrB_INT64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_apply(w, GrB_NULL, GrB_NULL, negative, u, GrB_NULL)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_fprint(w, GxB_COMPLETE)

GraphBLAS vector: w 
nrows: 3 ncols: 1 max # entries: 2
format: standard CSC vlen: 3 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  int64_t size: 8
number of entries: 2 
column: 0 : 2 entries [0:1]
    row 0: int64 -10
    row 2: int64 -20
```
"""
GrB_UnaryOp_new(
    op::Abstract_GrB_UnaryOp,
    fn::Function,
    ztype::Abstract_GrB_Type,
    xtype::Abstract_GrB_Type) = _NI("GrB_UnaryOp_new")

"""
    GrB_BinaryOp_new(op, fn, ztype, xtype, ytype)

Initialize a GraphBLAS binary operator with a specified user-defined function and its types.
The function should take 2 values(x, y) & return an output(z), f(x, y) = z.

# Examples
```jldoctest
julia> using GraphBLASInterface, SuiteSparseGraphBLAS

julia> GrB_init(GrB_NONBLOCKING)
GrB_SUCCESS::GrB_Info = 0

julia> V = GrB_Vector{Float64}()
GrB_Vector{Float64}

julia> GrB_Vector_new(V, GrB_FP64, 4)
GrB_SUCCESS::GrB_Info = 0

julia> I = ZeroBasedIndex[0, 0, 3, 3]; X = [2.1, 3.2, 4.5, 5.0]; n = 4;  # two values at position 0 and 3

julia> dup = GrB_BinaryOp()  # dup is a binary operator which is applied when duplicate values for the same location are present in the vector
GrB_BinaryOp

julia> function ADD(b, c)
           return b+c
       end
ADD (generic function with 1 method)

julia> GrB_BinaryOp_new(dup, ADD, GrB_FP64, GrB_FP64, GrB_FP64)
GrB_SUCCESS::GrB_Info = 0

julia> GrB_Vector_build(V, I, X, n, dup)
GrB_SUCCESS::GrB_Info = 0

julia> @GxB_Vector_fprint(V, GxB_COMPLETE) # the value stored at position 0 and 3 will be the sum of the duplicate values

GraphBLAS vector: V
nrows: 4 ncols: 1 max # entries: 2
format: standard CSC vlen: 4 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1
hyper_ratio 0.0625
GraphBLAS type:  double size: 8
number of entries: 2
column: 0 : 2 entries [0:1]
    row 0: double 5.3
    row 3: double 9.5
```
"""
GrB_BinaryOp_new(
    op::Abstract_GrB_BinaryOp,
    fn::Function,
    ztype::Abstract_GrB_Type,
    xtype::Abstract_GrB_Type,
    ytype::Abstract_GrB_Type) = _NI("GrB_BinaryOp_new")

"""
    GrB_Monoid_new(monoid, binary_op, identity)

Initialize a GraphBLAS monoid with specified binary operator and identity value.
"""
GrB_Monoid_new(
    monoid::Abstract_GrB_Monoid,
    binary_op::Abstract_GrB_BinaryOp,
    identity) = _NI("GrB_Monoid_new")

"""
    GrB_Semiring_new(semiring, monoid, binary_op)

Initialize a GraphBLAS semiring with specified monoid and binary operator.
"""
GrB_Semiring_new(
    semiring::Abstract_GrB_Semiring,
    monoid::Abstract_GrB_Monoid,
    binary_op::Abstract_GrB_BinaryOp) = _NI("GrB_Semiring_new")
