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

#ifndef COMPAPP_H
#define COMPAPP_H

#ifdef NUMBERS_INLINE_C
#define NUMBERS_INLINE
#else
#define NUMBERS_INLINE static __inline__
#endif

#include "acb.h"
#include "numbers/realApp.h"

#include "flint/fmpq.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef acb_struct compApp;
typedef compApp compApp_t[1];
typedef compApp * compApp_ptr;
typedef const compApp * compApp_srcptr;

#define compApp_realref(x) (&(x)->real)
#define compApp_imagref(x) (&(x)->imag)

/* memory managment */
NUMBERS_INLINE void compApp_init (compApp_t x) { acb_init (x); }
NUMBERS_INLINE void compApp_clear(compApp_t x) { acb_clear(x); }

/* members access */
NUMBERS_INLINE realApp_ptr compApp_real_ptr(compApp_t z                    ) { return acb_realref(z); }
NUMBERS_INLINE realApp_ptr compApp_imag_ptr(compApp_t z                    ) { return acb_imagref(z); }
NUMBERS_INLINE void        compApp_get_real(realApp_t re, const compApp_t z) { realApp_set(re, acb_realref(z));}
NUMBERS_INLINE void        compApp_get_imag(realApp_t im, const compApp_t z) { realApp_set(im, acb_imagref(z));}

/* setting */
NUMBERS_INLINE void compApp_swap(compApp_t z, compApp_t x      ) { acb_swap(z, x); }
NUMBERS_INLINE void compApp_zero(compApp_t z                   ) { acb_zero(z); }
NUMBERS_INLINE void compApp_one (compApp_t z                   ) { acb_one (z); }
NUMBERS_INLINE void compApp_onei(compApp_t z                   ) { acb_onei(z); }
NUMBERS_INLINE void compApp_set (compApp_t z, const compApp_t x) { acb_set (z, x); }
NUMBERS_INLINE void compApp_set_real_realApp(compApp_t x, const realApp_t re) { arb_set(acb_realref(x), re);}
NUMBERS_INLINE void compApp_set_imag_realApp(compApp_t x, const realApp_t im) { arb_set(acb_imagref(x), im);}

/* arithmetic */
NUMBERS_INLINE void compApp_abs   ( realApp_t dest, const compApp_t x, slong prec )                   { acb_abs   (dest, x, prec ); }
NUMBERS_INLINE void compApp_neg   ( compApp_t dest, const compApp_t x )                               { acb_neg   (dest, x ); }
NUMBERS_INLINE void compApp_sub   ( compApp_t dest, const compApp_t x, const compApp_t y, slong prec) { acb_sub   (dest, x, y, prec); }
NUMBERS_INLINE void compApp_add   ( compApp_t dest, const compApp_t x, const compApp_t y, slong prec) { acb_add   (dest, x, y, prec); }
NUMBERS_INLINE void compApp_mul   ( compApp_t dest, const compApp_t x, const compApp_t y, slong prec) { acb_mul   (dest, x, y, prec); }
NUMBERS_INLINE void compApp_div   ( compApp_t dest, const compApp_t x, const compApp_t y, slong prec) { acb_div   (dest, x, y, prec); }
NUMBERS_INLINE void compApp_mul_si( compApp_t dest, const compApp_t x, slong y,           slong prec) { acb_mul_si(dest, x, y, prec); }
NUMBERS_INLINE void compApp_div_si( compApp_t dest, const compApp_t x, slong y,           slong prec) { acb_div_si(dest, x, y, prec); }
NUMBERS_INLINE void compApp_addmul( compApp_t dest, const compApp_t x, const compApp_t y, slong prec) { acb_addmul(dest, x, y, prec); }
NUMBERS_INLINE void compApp_exp_pi_i( compApp_t dest, const compApp_t x, slong prec) { acb_exp_pi_i(dest, x, prec); }
NUMBERS_INLINE void compApp_pow_si( compApp_t dest, const compApp_t x, slong l, slong prec) { acb_pow_si(dest, x, l, prec); }

/* printing */
NUMBERS_INLINE void compApp_fprint (FILE * file, const compApp_t x)                           { acb_fprint (file, x               ); }
NUMBERS_INLINE void compApp_fprintd(FILE * file, const compApp_t x, slong digits)             { acb_fprintd(file, x, digits       ); }
NUMBERS_INLINE void compApp_fprintn(FILE * file, const compApp_t x, slong digits, ulong flags){ acb_fprintn(file, x, digits, flags); }  

NUMBERS_INLINE void compApp_print (const compApp_t x)                           { acb_print (x               ); }
NUMBERS_INLINE void compApp_printd(const compApp_t x, slong digits)             { acb_printd(x, digits       ); }
NUMBERS_INLINE void compApp_printn(const compApp_t x, slong digits, ulong flags){ acb_printn(x, digits, flags); }

/*interval operations*/
NUMBERS_INLINE int compApp_contains_zero (const compApp_t ball) {
    return acb_contains_zero(ball);
}
NUMBERS_INLINE int compApp_contains (const compApp_t x, const compApp_t y) {
    return acb_contains(x,y);
}
NUMBERS_INLINE int compApp_is_finite (const compApp_t z) {
    return acb_is_finite(z);
}

NUMBERS_INLINE int compApp_intersection(compApp_t z, const compApp_t x, const compApp_t y, slong prec) { 
    if (realApp_intersection( compApp_realref(z), compApp_realref(x), compApp_realref(y), prec) !=0)
        return realApp_intersection( compApp_imagref(z), compApp_imagref(x), compApp_imagref(y), prec);
    else return 0; 
}

/* accuracy */
NUMBERS_INLINE int compApp_checkAccuracy( const compApp_t z, slong prec) {
    return ( (-acb_rel_error_bits(z)) >= prec );
}

NUMBERS_INLINE slong compApp_getAccuracy( const compApp_t z) {
    return -acb_rel_error_bits(z);
}

#ifdef __cplusplus
}
#endif

#endif
