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

#ifndef DOUBCOMPAPP_POLY_H
#define DOUBCOMPAPP_POLY_H

#ifdef DOUBAPP_INLINE_C
#define DOUBAPP_INLINE
#else
#define DOUBAPP_INLINE static __inline__
#endif

#include "numbers/realRat.h"
#include "numbers/compRat.h"
#include "numbers/app_rat.h"
#include "polynomials/compApp_poly.h"
#include "doubCompApp.h"

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct
{
    doubCompApp_ptr coeffs;
    slong length;
    slong alloc;
}
doubCompApp_poly;

typedef doubCompApp_poly doubCompApp_poly_t[1];
typedef doubCompApp_poly * doubCompApp_poly_ptr;

/* Memory management */

void doubCompApp_poly_init(doubCompApp_poly_t poly);

void doubCompApp_poly_init2(doubCompApp_poly_t poly, slong len);

void doubCompApp_poly_clear(doubCompApp_poly_t poly);

void doubCompApp_poly_fit_length(doubCompApp_poly_t poly, slong len);

void _doubCompApp_poly_set_length(doubCompApp_poly_t poly, slong len);

void _doubCompApp_poly_normalise(doubCompApp_poly_t poly);

DOUBAPP_INLINE void
doubCompApp_poly_swap(doubCompApp_poly_t poly1, doubCompApp_poly_t poly2)
{
    doubCompApp_poly t = *poly1;
    *poly1 = *poly2;
    *poly2 = t;
}

DOUBAPP_INLINE slong doubCompApp_poly_length(const doubCompApp_poly_t poly)
{
    return poly->length;
}

DOUBAPP_INLINE slong doubCompApp_poly_degree(const doubCompApp_poly_t poly)
{
    return poly->length - 1;
}

/* setting */
DOUBAPP_INLINE void doubCompApp_poly_zero(doubCompApp_poly_t poly){
    poly->length = 0;
}

DOUBAPP_INLINE void doubCompApp_poly_one (doubCompApp_poly_t poly){
    doubCompApp_poly_fit_length(poly, 1);
    doubCompApp_one(poly->coeffs);
    _doubCompApp_poly_set_length(poly, 1);
}

DOUBAPP_INLINE void doubCompApp_poly_onei (doubCompApp_poly_t poly){
    doubCompApp_poly_fit_length(poly, 1);
    doubCompApp_onei(poly->coeffs);
    _doubCompApp_poly_set_length(poly, 1);
}

void doubCompApp_poly_set (doubCompApp_poly_t dest, const doubCompApp_poly_t src);
void doubCompApp_poly_set_compApp_poly (doubCompApp_poly_t dest, const compApp_poly_t src);

/* printing */
               void doubCompApp_poly_fprint (FILE * file, const doubCompApp_poly_t x);
DOUBAPP_INLINE void doubCompApp_poly_print (const doubCompApp_poly_t x) { doubCompApp_poly_fprint(stdout, x); }

/* Arithmetic */
void doubCompApp_poly_neg( doubCompApp_poly_t y, const doubCompApp_poly_t x);

void _doubCompApp_poly_add( doubCompApp_ptr z, doubCompApp_srcptr x, slong lenx, 
                                               doubCompApp_srcptr y, slong leny, slong len);
void doubCompApp_poly_add( doubCompApp_poly_t z, const doubCompApp_poly_t x, const doubCompApp_poly_t y);

void _doubCompApp_poly_sub( doubCompApp_ptr z, doubCompApp_srcptr x, slong lenx, 
                                               doubCompApp_srcptr y, slong leny, slong len);
void doubCompApp_poly_sub( doubCompApp_poly_t z, const doubCompApp_poly_t x, const doubCompApp_poly_t y);

void _doubCompApp_poly_shift_left(doubCompApp_ptr res, doubCompApp_srcptr poly, slong len, slong n);
void doubCompApp_poly_shift_left( doubCompApp_poly_t res, const doubCompApp_poly_t poly, slong n);

void _doubCompApp_poly_mul_si(doubCompApp_ptr res, slong lenres, slong s);
void doubCompApp_poly_mul_si( doubCompApp_poly_t res, const doubCompApp_poly_t x, slong s);

void _doubCompApp_poly_mullow_classical(doubCompApp_ptr res,
    doubCompApp_srcptr x, slong lenx,
    doubCompApp_srcptr y, slong leny, slong len);

void doubCompApp_poly_mul_classical( doubCompApp_poly_t res, const doubCompApp_poly_t x, const doubCompApp_poly_t y);
void _doubCompApp_poly_mullow_karatsuba(doubCompApp_ptr res, doubCompApp_srcptr x, slong lenx, doubCompApp_srcptr y, slong leny);
void doubCompApp_poly_mul_karatsuba( doubCompApp_poly_t res, const doubCompApp_poly_t x, const doubCompApp_poly_t y);
void _doubCompApp_poly_square_karatsuba(doubCompApp_ptr res, doubCompApp_srcptr x, slong lenx);
void doubCompApp_poly_sqr_karatsuba( doubCompApp_poly_t res, const doubCompApp_poly_t x);

void _doubCompApp_poly_reverse(doubCompApp_ptr res, doubCompApp_srcptr poly, slong len, slong n);
void _doubCompApp_poly_taylor_shift_convolution(doubCompApp_ptr p, const doubCompApp_t c, slong len);
// void doubCompApp_poly_taylorShift_in_place( doubCompApp_poly_t f, const compRat_t center, const realRat_t radius);

void _doubCompApp_poly_timesRXPC_inplace (doubCompApp_ptr p, const doubCompApp_t c, const doubRealApp_t r, slong len);
void _doubCompApp_poly_taylor_shift_horner( doubCompApp_ptr res, doubCompApp_srcptr src, const doubCompApp_t c, const doubRealApp_t r, slong len);
void doubCompApp_poly_taylor_shift_horner_inplace( doubCompApp_poly_t f, const doubCompApp_t c, const doubRealApp_t r);
void doubCompApp_poly_taylor_shift_horner( doubCompApp_poly_t res, const doubCompApp_poly_t f, const doubCompApp_t c, const doubRealApp_t r);
void doubCompApp_poly_taylor_shift_DQ( doubCompApp_poly_t res, doubCompApp_poly_t f, const doubCompApp_t c, const doubRealApp_t r);
void doubCompApp_poly_taylor_shift_convolution( doubCompApp_poly_t res, const doubCompApp_poly_t f, const doubCompApp_t c, const doubRealApp_t r);

void doubCompApp_poly_oneGraeffeIteration_in_place( doubCompApp_poly_t f );
/* DEPRECATED */
void doubCompApp_poly_mul_block( doubCompApp_poly_t res, const doubCompApp_poly_t x, const doubCompApp_poly_t y);

#ifdef __cplusplus
}
#endif

#endif
