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

#ifndef DOUBCOMPAPP_H
#define DOUBCOMPAPP_H

#ifdef DOUBAPP_INLINE_C
#define DOUBAPP_INLINE
#else
#define DOUBAPP_INLINE static __inline__
#endif

#include "numbers/compApp.h"
#include "doubRealApp.h"

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct
{
    doubRealApp real;
    doubRealApp imag;
}
doubCompApp;

typedef doubCompApp doubCompApp_t[1];
typedef doubCompApp * doubCompApp_ptr;
typedef const doubCompApp * doubCompApp_srcptr;

#define doubCompApp_realref(x) (&(x)->real)
#define doubCompApp_imagref(x) (&(x)->imag)

/* memory managment */
DOUBAPP_INLINE void doubCompApp_init(doubCompApp_t x) {
//     doubRealApp_init(doubCompApp_realref(x));
//     doubRealApp_init(doubCompApp_imagref(x));
}

DOUBAPP_INLINE void doubCompApp_clear(doubCompApp_t x){
//     doubRealApp_clear(doubCompApp_realref(x));
//     doubRealApp_clear(doubCompApp_imagref(x));
}

doubCompApp_ptr _doubCompApp_vec_init(slong n);
void _doubCompApp_vec_clear(doubCompApp_ptr v, slong n);

/* members access */
DOUBAPP_INLINE doubRealApp_ptr doubCompApp_real_ptr(doubCompApp_t z) { return doubCompApp_realref(z); }
DOUBAPP_INLINE doubRealApp_ptr doubCompApp_imag_ptr(doubCompApp_t z) { return doubCompApp_imagref(z); }

DOUBAPP_INLINE void doubCompApp_get_real(doubRealApp_t re, const doubCompApp_t z) { doubRealApp_set(re, doubCompApp_realref(z)); }
DOUBAPP_INLINE void doubCompApp_get_imag(doubRealApp_t im, const doubCompApp_t z) { doubRealApp_set(im, doubCompApp_imagref(z)); }

/* setting */
DOUBAPP_INLINE void doubCompApp_swap(doubCompApp_t z, doubCompApp_t x) {
    doubRealApp_swap(doubCompApp_realref(z), doubCompApp_realref(x));
    doubRealApp_swap(doubCompApp_imagref(z), doubCompApp_imagref(x));
}

DOUBAPP_INLINE void doubCompApp_zero(doubCompApp_t z) {
    doubRealApp_zero(doubCompApp_realref(z));
    doubRealApp_zero(doubCompApp_imagref(z));
}

DOUBAPP_INLINE void doubCompApp_one(doubCompApp_t z) {
    doubRealApp_one(doubCompApp_realref(z));
    doubRealApp_zero(doubCompApp_imagref(z));
}

DOUBAPP_INLINE void doubCompApp_onei(doubCompApp_t z) {
    doubRealApp_zero(doubCompApp_realref(z));
    doubRealApp_one(doubCompApp_imagref(z));
}

DOUBAPP_INLINE void doubCompApp_set(doubCompApp_t z, const doubCompApp_t x) {
    doubRealApp_set(doubCompApp_realref(z), doubCompApp_realref(x));
    doubRealApp_set(doubCompApp_imagref(z), doubCompApp_imagref(x));
}
DOUBAPP_INLINE void doubCompApp_set_compApp   (doubCompApp_t z, const compApp_t x ){
    doubRealApp_set_realApp   (doubCompApp_realref(z), compApp_realref(x) );
    doubRealApp_set_realApp   (doubCompApp_imagref(z), compApp_imagref(x) );
}
DOUBAPP_INLINE void doubCompApp_set_doubRealApp   (doubCompApp_t z, const doubRealApp_t x ){
    doubRealApp_set   (doubCompApp_realref(z), x );
    doubRealApp_zero  (doubCompApp_imagref(z));
}
DOUBAPP_INLINE void doubCompApp_get_compApp   (compApp_t z, const doubCompApp_t x ){
    doubRealApp_get_realApp   (compApp_realref(z), doubCompApp_realref(x) );
    doubRealApp_get_realApp   (compApp_imagref(z), doubCompApp_imagref(x) );
}

DOUBAPP_INLINE int doubCompApp_is_zero(const doubCompApp_t x) { 
    return doubRealApp_is_zero(doubCompApp_realref(x)) && doubRealApp_is_zero(doubCompApp_imagref(x));
}

DOUBAPP_INLINE int doubCompApp_is_one(const doubCompApp_t x) { 
    return doubRealApp_is_one(doubCompApp_realref(x)) && doubRealApp_is_zero(doubCompApp_imagref(x));
}

DOUBAPP_INLINE int doubCompApp_equal_si(const doubCompApp_t x, slong y) { 
    return doubRealApp_equal_si(doubCompApp_realref(x), y) && doubRealApp_is_zero(doubCompApp_imagref(x));
}
/* arithmetic */
// // DOUBAPP_INLINE void doubCompApp_abs   ( doubRealApp_t dest, const doubCompApp_t x, slong prec ) { 
// //     doubRealApp_hypot(dest, doubCompApp_realref(x), doubCompApp_imagref(x), prec); 
// // }

DOUBAPP_INLINE void doubCompApp_neg   ( doubCompApp_t dest, const doubCompApp_t x ) { 
    doubRealApp_neg(doubCompApp_realref(dest), doubCompApp_realref(x));
    doubRealApp_neg(doubCompApp_imagref(dest), doubCompApp_imagref(x)); 
}

DOUBAPP_INLINE void doubCompApp_sub   ( doubCompApp_t dest, const doubCompApp_t x, const doubCompApp_t y) { 
    doubRealApp_sub(doubCompApp_realref(dest), doubCompApp_realref(x), doubCompApp_realref(y));
    doubRealApp_sub(doubCompApp_imagref(dest), doubCompApp_imagref(x), doubCompApp_imagref(y));
}

DOUBAPP_INLINE void doubCompApp_add   ( doubCompApp_t dest, const doubCompApp_t x, const doubCompApp_t y) { 
    doubRealApp_add(doubCompApp_realref(dest), doubCompApp_realref(x), doubCompApp_realref(y));
    doubRealApp_add(doubCompApp_imagref(dest), doubCompApp_imagref(x), doubCompApp_imagref(y));
}
// 
// // void doubCompApp_sqr   ( doubCompApp_t z, const doubCompApp_t x );
void doubCompApp_mul   ( doubCompApp_t dest, const doubCompApp_t x, const doubCompApp_t y);
DOUBAPP_INLINE void doubCompApp_mul_onei ( doubCompApp_t z, const doubCompApp_t x){
    if (z == x)
    {
        doubRealApp_swap(doubCompApp_realref(z), doubCompApp_imagref(z));
        doubRealApp_neg(doubCompApp_realref(z), doubCompApp_realref(z));
    }
    else
    {
        doubRealApp_neg(doubCompApp_realref(z), doubCompApp_imagref(x));
        doubRealApp_set(doubCompApp_imagref(z), doubCompApp_realref(x));
    }
}
// // DOUBAPP_INLINE void doubCompApp_div   ( doubCompApp_t dest, const doubCompApp_t x, const doubCompApp_t y, slong prec) { acb_div   (dest, x, y, prec); }
// 
DOUBAPP_INLINE void doubCompApp_mul_si( doubCompApp_t dest, const doubCompApp_t x, slong y) { 
    doubRealApp_mul_si(doubCompApp_realref(dest), doubCompApp_realref(x), y);
    doubRealApp_mul_si(doubCompApp_imagref(dest), doubCompApp_imagref(x), y);
}

DOUBAPP_INLINE void doubCompApp_mul_ui( doubCompApp_t dest, const doubCompApp_t x, ulong y) { 
    doubRealApp_mul_ui(doubCompApp_realref(dest), doubCompApp_realref(x), y);
    doubRealApp_mul_ui(doubCompApp_imagref(dest), doubCompApp_imagref(x), y);
}

DOUBAPP_INLINE void doubCompApp_mul_doubRealApp( doubCompApp_t dest, const doubCompApp_t x, const doubRealApp_t y) { 
    doubRealApp_mul(doubCompApp_realref(dest), doubCompApp_realref(x), y);
    doubRealApp_mul(doubCompApp_imagref(dest), doubCompApp_imagref(x), y);
}

DOUBAPP_INLINE void doubCompApp_div_doubRealApp( doubCompApp_t dest, const doubCompApp_t x, const doubRealApp_t y) { 
    doubRealApp_div(doubCompApp_realref(dest), doubCompApp_realref(x), y);
    doubRealApp_div(doubCompApp_imagref(dest), doubCompApp_imagref(x), y);
}

// // DOUBAPP_INLINE void doubCompApp_div_si( doubCompApp_t dest, const doubCompApp_t x, slong y, slong prec) { 
// //     doubRealApp_div_si(doubCompApp_realref(dest), doubCompApp_realref(x), y, prec);
// //     doubRealApp_div_si(doubCompApp_imagref(dest), doubCompApp_imagref(x), y, prec);
// // }
// // DOUBAPP_INLINE void doubCompApp_addmul( doubCompApp_t dest, const doubCompApp_t x, const compApp_t y, slong prec) { acb_addmul(dest, x, y, prec); }
// // DOUBAPP_INLINE void doubCompApp_exp_pi_i( compApp_t dest, const compApp_t x, slong prec) { acb_exp_pi_i(dest, x, prec); }
// // DOUBAPP_INLINE void doubCompApp_pow_si( compApp_t dest, const compApp_t x, slong l, slong prec) { acb_pow_si(dest, x, l, prec); }
// 
               void doubCompApp_fprint (FILE * file, const doubCompApp_t x);
DOUBAPP_INLINE void doubCompApp_print (const doubCompApp_t x) { doubCompApp_fprint(stdout, x); }

#ifdef __cplusplus
}
#endif

#endif
