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

#ifndef REALRAT_H
#define REALRAT_H

#ifdef NUMBERS_INLINE_C
#define NUMBERS_INLINE
#else
#define NUMBERS_INLINE static __inline__
#endif

#include "flint/fmpz.h"
#include "flint/fmpq.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef fmpq realRat;
typedef realRat realRat_t[1];
typedef realRat * realRat_ptr;

#define realRat_numref(X) (&X->num)
#define realRat_denref(X) (&X->den)


/* memory managment */
NUMBERS_INLINE void realRat_init (realRat_t x) { fmpq_init (x); }
NUMBERS_INLINE void realRat_clear(realRat_t x) { fmpq_clear(x); }

/* setting */
NUMBERS_INLINE void realRat_set   (realRat_t dest, const realRat_t src) { fmpq_set   (dest, src);  }
NUMBERS_INLINE void realRat_set_si(realRat_t dest, slong p, ulong q)    { fmpq_set_si(dest, p, q); }
NUMBERS_INLINE void realRat_set_fmpz  (realRat_t dest, const fmpz_t src){
    fmpz_set(fmpq_numref(dest), src);
    fmpz_set_ui(fmpq_denref(dest), 1);
}

NUMBERS_INLINE int realRat_set_str  (realRat_t dest, const char * strN, const char * strD, int b){
    if (fmpz_set_str(fmpq_numref(dest), strN, b) == 0)
        return fmpz_set_str(fmpq_denref(dest), strD, b);
    else
        return -1;
}

/* normalizing */
NUMBERS_INLINE void realRat_canonicalise(realRat_t dest)    { fmpq_canonicalise(dest); }

/* comparisons */
NUMBERS_INLINE int  realRat_is_zero(const realRat_t x) { return fmpq_is_zero(x); }
/* returns negative if x<y, 0 if x==y, positive if x>y */
NUMBERS_INLINE int  realRat_cmp    (const realRat_t x, const realRat_t y) { return fmpq_cmp(x,y); }
NUMBERS_INLINE int  realRat_sgn    (const realRat_t x) { return fmpq_sgn(x); }

/* sets x to the min of x, y */
NUMBERS_INLINE void realRat_min_2_realRat(realRat_t x, const realRat_t y) {
    if (realRat_cmp(y,x)<0) 
        realRat_set(x, y );
}
/* sets x to the max of x, y */
NUMBERS_INLINE void realRat_max_2_realRat(realRat_t x, const realRat_t y) {
    if (realRat_cmp(y,x)>0) 
        realRat_set(x, y );
}

/* arithmetic operations */
NUMBERS_INLINE void realRat_abs(realRat_t dest, const realRat_t x)                    { fmpq_abs(dest, x); }
NUMBERS_INLINE void realRat_neg(realRat_t dest, const realRat_t x)                    { fmpq_neg(dest, x); }
NUMBERS_INLINE void realRat_mul(realRat_t dest, const realRat_t x, const realRat_t y) { fmpq_mul(dest, x, y); }
NUMBERS_INLINE void realRat_mul_si(realRat_t dest, const realRat_t x, slong y) { 
    fmpz_mul_si(realRat_numref(dest), realRat_numref(dest), y);
    realRat_canonicalise(dest);}
NUMBERS_INLINE void realRat_sub(realRat_t dest, const realRat_t x, const realRat_t y) { fmpq_sub(dest, x, y); }
NUMBERS_INLINE void realRat_add(realRat_t dest, const realRat_t x, const realRat_t y) { fmpq_add(dest, x, y); }
NUMBERS_INLINE void realRat_add_si(realRat_t dest, const realRat_t x, slong y) { fmpq_add_si(dest, x, y); }
NUMBERS_INLINE void realRat_div(realRat_t dest, const realRat_t x, const realRat_t y) { fmpq_div(dest, x, y); }

/*
NUMBERS_INLINE void realRat_div_ui(realRat_t dest, const realRat_t x, ulong y) { 
    fmpz_mul_si(realRat_denref(dest), realRat_denref(dest), y);
    realRat_canonicalise(dest);}
*/

NUMBERS_INLINE void realRat_pow_si(realRat_t dest, const realRat_t x, slong e) { fmpq_pow_si(dest, x, e); }
NUMBERS_INLINE void realRat_div_fmpz(realRat_t dest, const realRat_t x, const fmpz_t y) { fmpq_div_fmpz(dest, x, y); }
NUMBERS_INLINE void realRat_inv(realRat_t dest, const realRat_t x) { fmpq_inv(dest, x); }

/* printing */
NUMBERS_INLINE void realRat_print (const realRat_t x)              { fmpq_print (x); }
NUMBERS_INLINE void realRat_fprint(FILE * file, const realRat_t x) { fmpq_fprint(file, x); }

#ifdef __cplusplus
}
#endif

#endif
