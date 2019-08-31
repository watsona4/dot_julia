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

#ifndef REALAPP_H
#define REALAPP_H

#ifdef NUMBERS_INLINE_C
#define NUMBERS_INLINE
#else
#define NUMBERS_INLINE static __inline__
#endif

#include <math.h>
#include "arf.h"
#include "arb.h"
#include "flint/fmpz.h"
#include "flint/fmpq.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef arb_struct realApp;
typedef realApp realApp_t[1];
typedef realApp * realApp_ptr;

/* memory managment */
NUMBERS_INLINE void realApp_init (realApp_t x) { arb_init (x); }
NUMBERS_INLINE void realApp_clear(realApp_t x) { arb_clear(x); }

/* setting */
NUMBERS_INLINE void realApp_zero      (realApp_t x                                ) { arb_zero     (x); }
NUMBERS_INLINE void realApp_one       (realApp_t x                                ) { arb_one      (x); }
NUMBERS_INLINE void realApp_set       (realApp_t y, const realApp_t x             ) { arb_set      (y, x); }
NUMBERS_INLINE void realApp_set_fmpq  (realApp_t y, const fmpq_t    x, slong prec ) { arb_set_fmpq (y, x, prec); }
NUMBERS_INLINE void realApp_set_d     (realApp_t y, const double    x )             { arb_set_d (y, x); }

/* comparisons */
NUMBERS_INLINE int realApp_eq(const realApp_t x, const realApp_t y) { return arb_eq(x,y); }
NUMBERS_INLINE int realApp_ne(const realApp_t x, const realApp_t y) { return arb_ne(x,y); }
NUMBERS_INLINE int realApp_lt(const realApp_t x, const realApp_t y) { return arb_lt(x,y); }
NUMBERS_INLINE int realApp_le(const realApp_t x, const realApp_t y) { return arb_le(x,y); }
NUMBERS_INLINE int realApp_gt(const realApp_t x, const realApp_t y) { return arb_gt(x,y); }
NUMBERS_INLINE int realApp_ge(const realApp_t x, const realApp_t y) { return arb_ge(x,y); }

/* ball operations */
NUMBERS_INLINE int  realApp_is_finite(const realApp_t x) { return arb_is_finite( x ); }
NUMBERS_INLINE void realApp_get_rad_realApp(realApp_t z, const realApp_t x) { arb_get_rad_arb( z, x ); }
NUMBERS_INLINE void realApp_get_mid_realApp(realApp_t z, const realApp_t x) { arb_get_mid_arb( z, x ); }

NUMBERS_INLINE int  realApp_get_unique_si(slong * z, const realApp_t x) {
    fmpz_t zf;
    fmpz_init(zf);
    int res = arb_get_unique_fmpz( zf, x);
    res = res && fmpz_fits_si(zf);
    if (res)
        *z = fmpz_get_si(zf);
    fmpz_clear(zf);
    return res;
}

/* performed inplace */
NUMBERS_INLINE void realApp_add_error(realApp_t z, const realApp_t x) { arb_add_error( z, x ); }
/* interval operations */
NUMBERS_INLINE int  realApp_intersection(realApp_t z, const realApp_t x, const realApp_t y, slong prec) { 
    return arb_intersection( z, x, y, prec ); 
}
NUMBERS_INLINE int realApp_contains (const realApp_t x, const realApp_t y) {
    return arb_contains(x,y);
}
NUMBERS_INLINE int realApp_contains_zero (const realApp_t x) {
    return arb_contains_zero(x);
}

/* arithmetic operations */
NUMBERS_INLINE void realApp_add(realApp_t z, const realApp_t x, const realApp_t y, slong prec) { arb_add(z, x, y, prec); }
NUMBERS_INLINE void realApp_add_si(realApp_t z, const realApp_t x, slong y, slong prec) { arb_add_si(z, x, y, prec); }
NUMBERS_INLINE void realApp_sub(realApp_t z, const realApp_t x, const realApp_t y, slong prec) { arb_sub(z, x, y, prec); }
NUMBERS_INLINE void realApp_mul(realApp_t z, const realApp_t x, const realApp_t y, slong prec) { arb_mul(z, x, y, prec); }
NUMBERS_INLINE void realApp_neg(realApp_t z, const realApp_t x) { arb_neg(z, x); }
NUMBERS_INLINE void realApp_div(realApp_t z, const realApp_t x, const realApp_t y, slong prec) { arb_div(z, x, y, prec); }
NUMBERS_INLINE void realApp_pow_ui(realApp_t y, const realApp_t x, ulong e, slong prec) { arb_pow_ui(y, x, e, prec); }
NUMBERS_INLINE void realApp_root_ui(realApp_t y, const realApp_t x, ulong e, slong prec) { arb_root_ui(y, x, e, prec); }

/* logarithm */
NUMBERS_INLINE void realApp_log(realApp_t z, const realApp_t x, slong prec) { arb_log(z, x, prec); }
/* other */
NUMBERS_INLINE slong realApp_ceil_si(const realApp_t x, slong prec){
    slong res;
    arf_t ubound;
    arf_init(ubound);
    arb_get_ubound_arf(ubound, x, prec);
    res = (slong) ceil(arf_get_d(ubound,  ARF_RND_CEIL));
    arf_clear(ubound);
    return res;
}

/* printing */
NUMBERS_INLINE void realApp_fprint (FILE * file, const realApp_t x)                           { arb_fprint (file, x               ); }
NUMBERS_INLINE void realApp_fprintd(FILE * file, const realApp_t x, slong digits)             { arb_fprintd(file, x, digits       ); }
NUMBERS_INLINE void realApp_fprintn(FILE * file, const realApp_t x, slong digits, ulong flags){ arb_fprintn(file, x, digits, flags); }  

NUMBERS_INLINE void realApp_print (const realApp_t x)                           { arb_print (x               ); }
NUMBERS_INLINE void realApp_printd(const realApp_t x, slong digits)             { arb_printd(x, digits       ); }
NUMBERS_INLINE void realApp_printn(const realApp_t x, slong digits, ulong flags){ arb_printn(x, digits, flags); }

#ifdef __cplusplus
}
#endif

#endif
