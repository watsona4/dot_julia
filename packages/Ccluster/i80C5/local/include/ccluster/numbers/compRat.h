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

#ifndef COMPRAT_H
#define COMPRAT_H

#ifdef NUMBERS_INLINE_C
#define NUMBERS_INLINE
#else
#define NUMBERS_INLINE static __inline__
#endif

#include "numbers/realRat.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    realRat real;
    realRat imag;
} compRat;

typedef compRat compRat_t[1];
typedef compRat * compRat_ptr;

#define compRat_realref(X) (&(X)->real)
#define compRat_imagref(X) (&(X)->imag)

/* memory managment */
NUMBERS_INLINE void compRat_init(compRat_t x) { 
    realRat_init(compRat_realref(x)); 
    realRat_init(compRat_imagref(x));
}

NUMBERS_INLINE void compRat_clear(compRat_t x) { 
    realRat_clear(compRat_realref(x)); 
    realRat_clear(compRat_imagref(x));
}

/* members access */
NUMBERS_INLINE realRat_ptr compRat_real_ptr(compRat_t x) {
    return compRat_realref(x);
}

NUMBERS_INLINE realRat_ptr compRat_imag_ptr(compRat_t x) {
    return compRat_imagref(x);
}

NUMBERS_INLINE void compRat_get_real(realRat_t re, const compRat_t x) {
    realRat_set(re, compRat_realref(x));
}

NUMBERS_INLINE void compRat_get_imag(realRat_t im, const compRat_t x) {
    realRat_set(im, compRat_imagref(x));
}

/* setting */
NUMBERS_INLINE void compRat_set_2realRat(compRat_t x, const realRat_t re, const realRat_t im) { 
    realRat_set(compRat_realref(x), re); 
    realRat_set(compRat_imagref(x), im);
}

NUMBERS_INLINE void compRat_set_sisi(compRat_t x, slong preal, ulong qreal, slong pimag, ulong qimag) { 
    realRat_set_si(compRat_realref(x), preal, qreal); 
    realRat_set_si(compRat_imagref(x), pimag, qimag);
}

NUMBERS_INLINE int compRat_set_str  (compRat_t x, const char * strReN, const char * strReD, const char * strImN, const char * strImD, int b){
    if (realRat_set_str(compRat_realref(x), strReN, strReD, b) == 0)
        return realRat_set_str(compRat_imagref(x), strImN, strImD, b);
    else
        return -1;
}

NUMBERS_INLINE void compRat_set(compRat_t dest, const compRat_t src) { 
    realRat_set(compRat_realref(dest), compRat_realref(src)); 
    realRat_set(compRat_imagref(dest), compRat_imagref(src));
}

/* geometric operations */
/* sets dest to abs(x.real-y.real) + i*abs(x.imag-y.imag) */
void compRat_comp_distance( compRat_t dest, const compRat_t x, const compRat_t y );

/* comparisons */
/* returns negative if x.real<y.real or (x.real=y.real and x.imag<y.imag) */
/*                0 if x.real=y.real and x.imag=y.imag                    */
/*         positive if x.real>y.real or (x.real=y.real and x.imag>y.imag) */
int  compRat_cmp    (const compRat_t x, const compRat_t y);

/* printing */
void compRat_fprint(FILE * file, const compRat_t x);

NUMBERS_INLINE void compRat_print(const compRat_t x) {
    compRat_fprint(stdout, x);
}

#ifdef __cplusplus
}
#endif

#endif
