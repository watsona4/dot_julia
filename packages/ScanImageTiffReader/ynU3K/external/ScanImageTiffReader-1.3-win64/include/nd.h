#ifndef H_ND
#define H_ND

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

enum nd_type {
    nd_u8,
    nd_u16,
    nd_u32,
    nd_u64,
    nd_i8,
    nd_i16,
    nd_i32,
    nd_i64,
    nd_f32,
    nd_f64
};

/** Describes the shape and type of an
 *  n-dimensional scalar volume
 */
struct nd {
    unsigned ndim;        /**< The number of used dimensions */
    enum nd_type type;    /**< Indicates the scalar type */
    int64_t  strides[11]; /**< strides[i] is the number of elements in memory to move by 1 in dimension i. Should have length: 1+max # of dimensions */
    uint64_t dims[10];    /**< Number of elements in each dimension.  Max # of dimensions is 10 */
};

#ifdef __cplusplus
} //extern "C"
#endif


#endif /* header gaurd */
