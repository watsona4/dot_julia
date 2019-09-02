## Algebra methods

```@docs
GrB_Type_new
GrB_UnaryOp_new
GrB_BinaryOp_new
GrB_Monoid_new
GrB_Semiring_new
```

## Built-in algebraic objects

#### Unary operators, z = f(x)

```
z and x have the same type. The suffix in the name is the type of x and z.

z = x                z = -x            z = 1/x
identity             additive          multiplicative
                     inverse           inverse

GrB_IDENTITY_BOOL    GrB_AINV_BOOL     GrB_MINV_BOOL
GrB_IDENTITY_INT8    GrB_AINV_INT8     GrB_MINV_INT8
GrB_IDENTITY_UINT8   GrB_AINV_UINT8    GrB_MINV_UINT8
GrB_IDENTITY_INT16   GrB_AINV_INT16    GrB_MINV_INT16
GrB_IDENTITY_UINT16  GrB_AINV_UINT16   GrB_MINV_UINT16
GrB_IDENTITY_INT32   GrB_AINV_INT32    GrB_MINV_INT32
GrB_IDENTITY_UINT32  GrB_AINV_UINT32   GrB_MINV_UINT32
GrB_IDENTITY_INT64   GrB_AINV_INT64    GrB_MINV_INT64
GrB_IDENTITY_UINT64  GrB_AINV_UINT64   GrB_MINV_UINT64
GrB_IDENTITY_FP32    GrB_AINV_FP32     GrB_MINV_FP32
GrB_IDENTITY_FP64    GrB_AINV_FP64     GrB_MINV_FP64

z = !x, where both z and x are boolean. 
There is no suffix since z and x are only boolean.

GrB_LNOT
```

#### Binary operators, z = f(x,y)

```
x,y,z all have the same type :

z = x              z = y              z = min(x,y)       z = max (x,y)

GrB_FIRST_BOOL     GrB_SECOND_BOOL    GrB_MIN_BOOL       GrB_MAX_BOOL
GrB_FIRST_INT8     GrB_SECOND_INT8    GrB_MIN_INT8       GrB_MAX_INT8
GrB_FIRST_UINT8    GrB_SECOND_UINT8   GrB_MIN_UINT8      GrB_MAX_UINT8
GrB_FIRST_INT16    GrB_SECOND_INT16   GrB_MIN_INT16      GrB_MAX_INT16
GrB_FIRST_UINT16   GrB_SECOND_UINT16  GrB_MIN_UINT16     GrB_MAX_UINT16
GrB_FIRST_INT32    GrB_SECOND_INT32   GrB_MIN_INT32      GrB_MAX_INT32
GrB_FIRST_UINT32   GrB_SECOND_UINT32  GrB_MIN_UINT32     GrB_MAX_UINT32
GrB_FIRST_INT64    GrB_SECOND_INT64   GrB_MIN_INT64      GrB_MAX_INT64
GrB_FIRST_UINT64   GrB_SECOND_UINT64  GrB_MIN_UINT64     GrB_MAX_UINT64
GrB_FIRST_FP32     GrB_SECOND_FP32    GrB_MIN_FP32       GrB_MAX_FP32
GrB_FIRST_FP64     GrB_SECOND_FP64    GrB_MIN_FP64       GrB_MAX_FP64

z = x+y            z = x-y            z = x*y            z = x/y

GrB_PLUS_BOOL      GrB_MINUS_BOOL     GrB_TIMES_BOOL     GrB_DIV_BOOL
GrB_PLUS_INT8      GrB_MINUS_INT8     GrB_TIMES_INT8     GrB_DIV_INT8
GrB_PLUS_UINT8     GrB_MINUS_UINT8    GrB_TIMES_UINT8    GrB_DIV_UINT8
GrB_PLUS_INT16     GrB_MINUS_INT16    GrB_TIMES_INT16    GrB_DIV_INT16
GrB_PLUS_UINT16    GrB_MINUS_UINT16   GrB_TIMES_UINT16   GrB_DIV_UINT16
GrB_PLUS_INT32     GrB_MINUS_INT32    GrB_TIMES_INT32    GrB_DIV_INT32
GrB_PLUS_UINT32    GrB_MINUS_UINT32   GrB_TIMES_UINT32   GrB_DIV_UINT32
GrB_PLUS_INT64     GrB_MINUS_INT64    GrB_TIMES_INT64    GrB_DIV_INT64
GrB_PLUS_UINT64    GrB_MINUS_UINT64   GrB_TIMES_UINT64   GrB_DIV_UINT64
GrB_PLUS_FP32      GrB_MINUS_FP32     GrB_TIMES_FP32     GrB_DIV_FP32
GrB_PLUS_FP64      GrB_MINUS_FP64     GrB_TIMES_FP64     GrB_DIV_FP64

z is always boolean & x,y have the same type :

z = (x == y)       z = (x != y)       z = (x > y)        z = (x < y)

GrB_EQ_BOOL        GrB_NE_BOOL        GrB_GT_BOOL        GrB_LT_BOOL
GrB_EQ_INT8        GrB_NE_INT8        GrB_GT_INT8        GrB_LT_INT8
GrB_EQ_UINT8       GrB_NE_UINT8       GrB_GT_UINT8       GrB_LT_UINT8
GrB_EQ_INT16       GrB_NE_INT16       GrB_GT_INT16       GrB_LT_INT16
GrB_EQ_UINT16      GrB_NE_UINT16      GrB_GT_UINT16      GrB_LT_UINT16
GrB_EQ_INT32       GrB_NE_INT32       GrB_GT_INT32       GrB_LT_INT32
GrB_EQ_UINT32      GrB_NE_UINT32      GrB_GT_UINT32      GrB_LT_UINT32
GrB_EQ_INT64       GrB_NE_INT64       GrB_GT_INT64       GrB_LT_INT64
GrB_EQ_UINT64      GrB_NE_UINT64      GrB_GT_UINT64      GrB_LT_UINT64
GrB_EQ_FP32        GrB_NE_FP32        GrB_GT_FP32        GrB_LT_FP32
GrB_EQ_FP64        GrB_NE_FP64        GrB_GT_FP64        GrB_LT_FP64

z = (x >= y)       z = (x <= y)

GrB_GE_BOOL        GrB_LE_BOOL
GrB_GE_INT8        GrB_LE_INT8
GrB_GE_UINT8       GrB_LE_UINT8
GrB_GE_INT16       GrB_LE_INT16
GrB_GE_UINT16      GrB_LE_UINT16
GrB_GE_INT32       GrB_LE_INT32
GrB_GE_UINT32      GrB_LE_UINT32
GrB_GE_INT64       GrB_LE_INT64
GrB_GE_UINT64      GrB_LE_UINT64
GrB_GE_FP32        GrB_LE_FP32
GrB_GE_FP64        GrB_LE_FP64

x,y,z all are boolean :

z = (x || y)       z = (x && y)       z = (x != y)

GrB_LOR            GrB_LAND           GrB_LXOR
```

