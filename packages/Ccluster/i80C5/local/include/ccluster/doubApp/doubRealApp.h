/* ************************************************************************** */
/*  Copyright (C) 2018 Remi Imbach                                            */
/*                                                                            */
/*  This file is part of Ccluster.                                            */
/*                                                                            */
/*  Ccluster is free software: you can redistribute it and/or modify it under */
/*  the terms of the GNU Lesser General Public License (LGPL) as published    */
/*  by the Free Software Foundation; either version 2.1 of the License, or    */
/*  (at your option) any later version.  See <http://www.gnu.org/licenses/>.  */
/* ************************************************************************** */

#ifndef DOUBREALAPP_H
#define DOUBREALAPP_H

#ifdef DOUBAPP_INLINE_C
#define DOUBAPP_INLINE
#else
#define DOUBAPP_INLINE static __inline__
#endif

#include <math.h>
// #include "arb.h"
#include "flint/fmpq.h"

#include "base/base.h"
#include "numbers/realRat.h"
#include "numbers/realApp.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef double number;
// typedef long double number;

typedef struct {
    /* Assuming rounding upward; 
     *low stores MINUS the lower 
     * bound of the interval;*/
    number low;
    number upp;
} doubRealApp;

typedef doubRealApp doubRealApp_t[1];
typedef doubRealApp * doubRealApp_ptr;

#define doubRealApp_lowref(x) (&(x)->low)
#define doubRealApp_uppref(x) (&(x)->upp)

/* memory managment */
DOUBAPP_INLINE void doubRealApp_init (doubRealApp_t x) {  }
DOUBAPP_INLINE void doubRealApp_clear(doubRealApp_t x) {  }
               void doubRealApp_swap(doubRealApp_t x, doubRealApp_t y);

/* setting */

DOUBAPP_INLINE void doubRealApp_zero      (doubRealApp_t x                                ) { x->low=0.; x->upp=0.;  }
DOUBAPP_INLINE void doubRealApp_one       (doubRealApp_t x                                ) { x->low=-1.; x->upp=1.; }
DOUBAPP_INLINE void doubRealApp_set       (doubRealApp_t y, const doubRealApp_t x         ) { y->low = x->low; y->upp=x->upp; }
// DOUBAPP_INLINE void doubRealApp_set_fmpq  (doubRealApp_t y, const fmpq_t    x, slong prec ) { arb_set_fmpq (y, x, prec); }
DOUBAPP_INLINE void doubRealApp_set_d     (doubRealApp_t y, const double    x )             { y->low = -x; y->upp = x; }
               void doubRealApp_set_realApp   (doubRealApp_t y, const realApp_t x );
               void doubRealApp_get_realApp   (realApp_t y, const doubRealApp_t x );

/* comparisons */
DOUBAPP_INLINE int doubRealApp_is_zero(const doubRealApp_t x) { return (x->low==0.) && (x->upp==0.); }
DOUBAPP_INLINE int doubRealApp_is_one(const doubRealApp_t x) { return (x->low==-1) && (x->upp==1); }
DOUBAPP_INLINE int doubRealApp_is_exact(const doubRealApp_t x) { return (x->low==-x->upp); }
DOUBAPP_INLINE int doubRealApp_contains_zero(const doubRealApp_t x) { return (x->low>=0.) && (x->upp>=0.); }
DOUBAPP_INLINE int doubRealApp_is_positive(const doubRealApp_t x) { return (x->low<=0.); }
DOUBAPP_INLINE int doubRealApp_is_negative(const doubRealApp_t x) { return (x->upp<=0.); }
DOUBAPP_INLINE int doubRealApp_equal_si(const doubRealApp_t x, slong y) { return (x->upp==y) && (x->low==-y); }
// DOUBAPP_INLINE int doubRealApp_eq(const doubRealApp_t x, const doubRealApp_t y) { return arb_eq(x,y); }
// DOUBAPP_INLINE int doubRealApp_ne(const doubRealApp_t x, const doubRealApp_t y) { return arb_ne(x,y); }
// DOUBAPP_INLINE int doubRealApp_lt(const doubRealApp_t x, const doubRealApp_t y) { return arb_lt(x,y); }
// DOUBAPP_INLINE int doubRealApp_le(const doubRealApp_t x, const doubRealApp_t y) { return arb_le(x,y); }
// DOUBAPP_INLINE int doubRealApp_gt(const doubRealApp_t x, const doubRealApp_t y) { return arb_gt(x,y); }
// DOUBAPP_INLINE int doubRealApp_ge(const doubRealApp_t x, const doubRealApp_t y) { return arb_ge(x,y); }

/* ball operations */
// DOUBAPP_INLINE int  doubRealApp_is_finite(const doubRealApp_t x) { 
//     return isfinite( x->mid ) && isfinite( x->rad ); 
// }
// DOUBAPP_INLINE void doubRealApp_get_rad_doubRealApp(doubRealApp_t y, const doubRealApp_t x) { y->mid = x->rad; y->rad = 0.; }
//                void doubRealApp_get_mid_doubRealApp(doubRealApp_t y, const doubRealApp_t x);
/* interval operations */
// DOUBAPP_INLINE int  doubRealApp_intersection(doubRealApp_t z, const doubRealApp_t x, const doubRealApp_t y, slong prec) { 
//     return arb_intersection( z, x, y, prec ); 
// }

/* arithmetic operations */
               void doubRealApp_add(doubRealApp_t res, const doubRealApp_t x, const doubRealApp_t y);
               void doubRealApp_sub(doubRealApp_t res, const doubRealApp_t x, const doubRealApp_t y);
               void doubRealApp_sqr(doubRealApp_t res, const doubRealApp_t x);
               void _doubRealApp_mul(doubRealApp_t res, const doubRealApp_t x, const doubRealApp_t y);
DOUBAPP_INLINE void doubRealApp_mul(doubRealApp_t res, const doubRealApp_t x, const doubRealApp_t y){
    if (x==y)
        doubRealApp_sqr(res, x);
    else
        _doubRealApp_mul(res, x, y);
}

               void doubRealApp_mul_si   (doubRealApp_t res, const doubRealApp_t x,  slong y);
               void doubRealApp_mul_ui   (doubRealApp_t res, const doubRealApp_t x,  ulong y);
               void doubRealApp_neg(doubRealApp_t res, const doubRealApp_t x);
               void doubRealApp_inv(doubRealApp_t z, const doubRealApp_t x);              
DOUBAPP_INLINE void doubRealApp_div(doubRealApp_t z, const doubRealApp_t x, const doubRealApp_t y){
    doubRealApp_t t;
    doubRealApp_inv(t, y);
    doubRealApp_mul(z, x, t);
}
               
//                void doubRealApp_addmul   (doubRealApp_t res, const doubRealApp_t x,  const doubRealApp_t y);               
// DOUBAPP_INLINE void doubRealApp_pow_ui(doubRealApp_t y, const doubRealApp_t x, ulong e, slong prec) { arb_pow_ui(y, x, e, prec); }
// DOUBAPP_INLINE void doubRealApp_root_ui(doubRealApp_t y, const doubRealApp_t x, ulong e, slong prec) { arb_root_ui(y, x, e, prec); }

// 
// DOUBAPP_INLINE void doubRealApp_hypot( doubRealApp_t z, const doubRealApp_t x, const doubRealApp_t y, slong prec) {
//     arb_hypot(z, x, y, prec);
// }
// DOUBAPP_INLINE void doubRealApp_mul_si(doubRealApp_t z, const doubRealApp_t x, slong y, slong prec) { arb_mul_si(z, x, y, prec); }
// DOUBAPP_INLINE void doubRealApp_div_si(doubRealApp_t z, const doubRealApp_t x, slong y, slong prec) { arb_div_si(z, x, y, prec); }
/* printing */
               void doubRealApp_fprint (FILE * file, const doubRealApp_t x);
// DOUBAPP_INLINE void doubRealApp_fprintd(FILE * file, const doubRealApp_t x, slong digits)             { arb_fprintd(file, x, digits       ); }
// DOUBAPP_INLINE void doubRealApp_fprintn(FILE * file, const doubRealApp_t x, slong digits, ulong flags){ arb_fprintn(file, x, digits, flags); }  
// 
DOUBAPP_INLINE void doubRealApp_print (const doubRealApp_t x) { doubRealApp_fprint(stdout, x); }
// DOUBAPP_INLINE void doubRealApp_printd(const doubRealApp_t x, slong digits)             { arb_printd(x, digits       ); }
// DOUBAPP_INLINE void doubRealApp_printn(const doubRealApp_t x, slong digits, ulong flags){ arb_printn(x, digits, flags); }


#ifdef __cplusplus
}
#endif

#endif
