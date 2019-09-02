module GraphBLASInterface

include("structures.jl")

const accum_type = Union{Abstract_GrB_BinaryOp, Abstract_GrB_NULL}
const matrix_mask_type = Union{Abstract_GrB_Matrix, Abstract_GrB_NULL}
const vector_mask_type = Union{Abstract_GrB_Vector, Abstract_GrB_NULL}
const desc_type = Union{Abstract_GrB_Descriptor, Abstract_GrB_NULL}
const indices_type = Union{Vector{<:Abstract_GrB_Index}, Abstract_GrB_ALL}

_NI(m) = error("Not implemented: $m")

include("enums.jl")
include("context_methods.jl")
include("sequence_termination.jl")
include("object_methods/matrix_methods.jl")
include("object_methods/vector_methods.jl")
include("object_methods/algebra_methods.jl")
include("object_methods/descriptor_methods.jl")
include("object_methods/free_methods.jl")
include("operations/multiplication.jl")
include("operations/element_wise_multiplication.jl")
include("operations/element_wise_addition.jl")
include("operations/extract.jl")
include("operations/apply.jl")
include("operations/assign.jl")
include("operations/reduce.jl")
include("operations/transpose.jl")

export
#########################################################################
#                       GraphBLAS types                                 #
#########################################################################

GrB_BOOL,
GrB_INT8,
GrB_UINT8,
GrB_INT16,
GrB_UINT16,
GrB_INT32,
GrB_UINT32,
GrB_INT64,
GrB_UINT64,
GrB_FP32,
GrB_FP64,

#########################################################################
#                    Built-in unary operators                           #
#########################################################################

# z and x have the same type. The suffix in the name is the type of x and z.

# z = x               z = -x             z = 1/x
# identity            additive           multiplicative
#                     inverse            inverse
GrB_IDENTITY_BOOL,    GrB_AINV_BOOL,     GrB_MINV_BOOL,
GrB_IDENTITY_INT8,    GrB_AINV_INT8,     GrB_MINV_INT8,
GrB_IDENTITY_UINT8,   GrB_AINV_UINT8,    GrB_MINV_UINT8,
GrB_IDENTITY_INT16,   GrB_AINV_INT16,    GrB_MINV_INT16,
GrB_IDENTITY_UINT16,  GrB_AINV_UINT16,   GrB_MINV_UINT16,
GrB_IDENTITY_INT32,   GrB_AINV_INT32,    GrB_MINV_INT32,
GrB_IDENTITY_UINT32,  GrB_AINV_UINT32,   GrB_MINV_UINT32,
GrB_IDENTITY_INT64,   GrB_AINV_INT64,    GrB_MINV_INT64,
GrB_IDENTITY_UINT64,  GrB_AINV_UINT64,   GrB_MINV_UINT64,
GrB_IDENTITY_FP32,    GrB_AINV_FP32,     GrB_MINV_FP32,
GrB_IDENTITY_FP64,    GrB_AINV_FP64,     GrB_MINV_FP64,

# z = !x, where both z and x are boolean.
# There is no suffix since z and x are only boolean.
GrB_LNOT,

#########################################################################
#                    Built-in binary operators                          #
#########################################################################

# x,y,z all have the same type :

# z = x             z = y               z = min(x,y)        z = max (x,y)
GrB_FIRST_BOOL,     GrB_SECOND_BOOL,    GrB_MIN_BOOL,       GrB_MAX_BOOL,
GrB_FIRST_INT8,     GrB_SECOND_INT8,    GrB_MIN_INT8,       GrB_MAX_INT8,
GrB_FIRST_UINT8,    GrB_SECOND_UINT8,   GrB_MIN_UINT8,      GrB_MAX_UINT8,
GrB_FIRST_INT16,    GrB_SECOND_INT16,   GrB_MIN_INT16,      GrB_MAX_INT16,
GrB_FIRST_UINT16,   GrB_SECOND_UINT16,  GrB_MIN_UINT16,     GrB_MAX_UINT16,
GrB_FIRST_INT32,    GrB_SECOND_INT32,   GrB_MIN_INT32,      GrB_MAX_INT32,
GrB_FIRST_UINT32,   GrB_SECOND_UINT32,  GrB_MIN_UINT32,     GrB_MAX_UINT32,
GrB_FIRST_INT64,    GrB_SECOND_INT64,   GrB_MIN_INT64,      GrB_MAX_INT64,
GrB_FIRST_UINT64,   GrB_SECOND_UINT64,  GrB_MIN_UINT64,     GrB_MAX_UINT64,
GrB_FIRST_FP32,     GrB_SECOND_FP32,    GrB_MIN_FP32,       GrB_MAX_FP32,
GrB_FIRST_FP64,     GrB_SECOND_FP64,    GrB_MIN_FP64,       GrB_MAX_FP64,

# z = x+y           z = x-y             z = x*y             z = x/y
GrB_PLUS_BOOL,      GrB_MINUS_BOOL,     GrB_TIMES_BOOL,     GrB_DIV_BOOL,
GrB_PLUS_INT8,      GrB_MINUS_INT8,     GrB_TIMES_INT8,     GrB_DIV_INT8,
GrB_PLUS_UINT8,     GrB_MINUS_UINT8,    GrB_TIMES_UINT8,    GrB_DIV_UINT8,
GrB_PLUS_INT16,     GrB_MINUS_INT16,    GrB_TIMES_INT16,    GrB_DIV_INT16,
GrB_PLUS_UINT16,    GrB_MINUS_UINT16,   GrB_TIMES_UINT16,   GrB_DIV_UINT16,
GrB_PLUS_INT32,     GrB_MINUS_INT32,    GrB_TIMES_INT32,    GrB_DIV_INT32,
GrB_PLUS_UINT32,    GrB_MINUS_UINT32,   GrB_TIMES_UINT32,   GrB_DIV_UINT32,
GrB_PLUS_INT64,     GrB_MINUS_INT64,    GrB_TIMES_INT64,    GrB_DIV_INT64,
GrB_PLUS_UINT64,    GrB_MINUS_UINT64,   GrB_TIMES_UINT64,   GrB_DIV_UINT64,
GrB_PLUS_FP32,      GrB_MINUS_FP32,     GrB_TIMES_FP32,     GrB_DIV_FP32,
GrB_PLUS_FP64,      GrB_MINUS_FP64,     GrB_TIMES_FP64,     GrB_DIV_FP64,

# z is always boolean & x,y have the same type :

# z = (x == y)      z = (x != y)        z = (x > y)         z = (x < y)
GrB_EQ_BOOL,        GrB_NE_BOOL,        GrB_GT_BOOL,        GrB_LT_BOOL,
GrB_EQ_INT8,        GrB_NE_INT8,        GrB_GT_INT8,        GrB_LT_INT8,
GrB_EQ_UINT8,       GrB_NE_UINT8,       GrB_GT_UINT8,       GrB_LT_UINT8,
GrB_EQ_INT16,       GrB_NE_INT16,       GrB_GT_INT16,       GrB_LT_INT16,
GrB_EQ_UINT16,      GrB_NE_UINT16,      GrB_GT_UINT16,      GrB_LT_UINT16,
GrB_EQ_INT32,       GrB_NE_INT32,       GrB_GT_INT32,       GrB_LT_INT32,
GrB_EQ_UINT32,      GrB_NE_UINT32,      GrB_GT_UINT32,      GrB_LT_UINT32,
GrB_EQ_INT64,       GrB_NE_INT64,       GrB_GT_INT64,       GrB_LT_INT64,
GrB_EQ_UINT64,      GrB_NE_UINT64,      GrB_GT_UINT64,      GrB_LT_UINT64,
GrB_EQ_FP32,        GrB_NE_FP32,        GrB_GT_FP32,        GrB_LT_FP32,
GrB_EQ_FP64,        GrB_NE_FP64,        GrB_GT_FP64,        GrB_LT_FP64,

# z = (x >= y)      z = (x <= y)
GrB_GE_BOOL,        GrB_LE_BOOL,
GrB_GE_INT8,        GrB_LE_INT8,
GrB_GE_UINT8,       GrB_LE_UINT8,
GrB_GE_INT16,       GrB_LE_INT16,
GrB_GE_UINT16,      GrB_LE_UINT16,
GrB_GE_INT32,       GrB_LE_INT32,
GrB_GE_UINT32,      GrB_LE_UINT32,
GrB_GE_INT64,       GrB_LE_INT64,
GrB_GE_UINT64,      GrB_LE_UINT64,
GrB_GE_FP32,        GrB_LE_FP32,
GrB_GE_FP64,        GrB_LE_FP64,

# x,y,z all are boolean :

# z = (x || y)      z = (x && y)        z = (x != y)
GrB_LOR,            GrB_LAND,           GrB_LXOR,

#########################################################################
#                       Context Methods                                 #
#########################################################################

GrB_init, GrB_finalize,

#########################################################################
#                       Object Methods                                  #
#########################################################################

has_offset_indices,

# Matrix Methods
GrB_Matrix, GrB_Matrix_new, GrB_Matrix_build, GrB_Matrix_dup, GrB_Matrix_clear,
GrB_Matrix_nrows, GrB_Matrix_ncols, GrB_Matrix_nvals, GrB_Matrix_setElement,
GrB_Matrix_extractElement, GrB_Matrix_extractTuples,

# Vector Methods
GrB_Vector, GrB_Vector_new, GrB_Vector_build, GrB_Vector_dup, GrB_Vector_clear, 
GrB_Vector_size, GrB_Vector_nvals, GrB_Vector_setElement, GrB_Vector_extractElement, 
GrB_Vector_extractTuples,

# Descriptor Methods
GrB_Descriptor, GrB_Descriptor_new, GrB_Descriptor_set,

# Algebra Methods
GrB_Type, GrB_Type_new, GrB_UnaryOp, GrB_UnaryOp_new, GrB_BinaryOp, GrB_BinaryOp_new, 
GrB_Monoid, GrB_Monoid_new, GrB_Semiring, GrB_Semiring_new,

# Free Methods
GrB_free, GrB_Type_free, GrB_UnaryOp_free, GrB_BinaryOp_free, GrB_Monoid_free, 
GrB_Semiring_free, GrB_Vector_free, GrB_Matrix_free, GrB_Descriptor_free,

#########################################################################
#                            Operations                                 #
#########################################################################

# Multiplication
GrB_mxm, GrB_vxm, GrB_mxv,

# Element wise multiplication
GrB_eWiseMult_Vector_Semiring, GrB_eWiseMult_Vector_Monoid, GrB_eWiseMult_Vector_BinaryOp,
GrB_eWiseMult_Matrix_Semiring, GrB_eWiseMult_Matrix_Monoid, GrB_eWiseMult_Matrix_BinaryOp,
GrB_eWiseMult,

# Element wise addition
GrB_eWiseAdd_Vector_Semiring, GrB_eWiseAdd_Vector_Monoid, GrB_eWiseAdd_Vector_BinaryOp,
GrB_eWiseAdd_Matrix_Semiring, GrB_eWiseAdd_Matrix_Monoid, GrB_eWiseAdd_Matrix_BinaryOp,
GrB_eWiseAdd,

# Extract
GrB_extract, GrB_Vector_extract, GrB_Matrix_extract, GrB_Col_extract,

# Apply
GrB_apply, GrB_Vector_apply, GrB_Matrix_apply,

# Assign
GrB_assign, GrB_Vector_assign, GrB_Matrix_assign, GrB_Col_assign, GrB_Row_assign,

# Reduce
GrB_reduce, GrB_Matrix_reduce_Monoid, GrB_Matrix_reduce_BinaryOp, GrB_Matrix_reduce,
GrB_Vector_reduce,

# Transpose
GrB_transpose,

#########################################################################
#                       Sequence Termination                            # 
#########################################################################

GrB_wait, GrB_error

#########################################################################
#                              Enums                                    # 
#########################################################################

export GrB_Info
for s in instances(GrB_Info)
    @eval export $(Symbol(s))
end

export GrB_Mode
for s in instances(GrB_Mode)
    @eval export $(Symbol(s))
end

export GrB_Desc_Field
for s in instances(GrB_Desc_Field)
    @eval export $(Symbol(s))
end

export GrB_Desc_Value
for s in instances(GrB_Desc_Value)
    @eval export $(Symbol(s))
end

# GrB_NULL
export GrB_NULL

# GrB_ALL
export GrB_ALL

end # module
