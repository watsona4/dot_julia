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

#ifndef APPRAT_POLY_H
#define APPRAT_POLY_H

#ifdef POLYNOMIALS_INLINE_C
#define POLYNOMIALS_INLINE
#else
#define POLYNOMIALS_INLINE static __inline__
#endif

#include "numbers/app_rat.h"
#include "polynomials/realRat_poly.h"
#include "polynomials/compRat_poly.h"
#include "polynomials/compApp_poly.h"

#ifdef __cplusplus
extern "C" {
#endif

/* converting realRat_poly to compApp_poly  */
POLYNOMIALS_INLINE void compApp_poly_set_realRat_poly(compApp_poly_t poly, const realRat_poly_t re, slong prec) {
    compApp_poly_set_fmpq_poly(poly, re, prec);
}

/* converting compRat_poly to compApp_poly  */
POLYNOMIALS_INLINE void compApp_poly_set_compRat_poly(compApp_poly_t poly, const compRat_poly_t pRat, slong prec) {
    compApp_poly_set2_fmpq_poly(poly, compRat_poly_realref(pRat), compRat_poly_imagref(pRat), prec);
}

/* scaling in place */
/* requires: r is canonical */ 
void compApp_poly_scale_realRat_in_place( compApp_ptr fptr, const realRat_t r, slong len, slong prec );

/*
void compApp_poly_taylorShift_in_place( compApp_poly_t f, const realRat_t creal, const realRat_t cimag, const realRat_t radius, slong prec );
*/
void compApp_poly_taylorShift_in_place( compApp_poly_t f, const compRat_t center, const realRat_t radius, slong prec );

void compApp_poly_taylorShift( compApp_poly_t res, 
                               const compApp_poly_t f, 
                               const compRat_t center, const realRat_t radius, 
                               slong prec );

/*void compApp_poly_taylorShift_in_place_new( compApp_poly_t f, const realRat_t creal, const realRat_t cimag, const realRat_t radius, slong prec );*/
void compApp_poly_taylor_shift_convolution_without_pre(compApp_poly_t dest, const compApp_poly_t p, 
                                                       realApp_t f, compApp_ptr t, 
                                                       const realRat_t creal, const realRat_t cimag, const realRat_t radius,
                                                       slong prec);

void compApp_poly_taylorShift_new( compApp_poly_t res, 
                               const compApp_poly_t f, 
                               const realRat_t creal, const realRat_t cimag, const realRat_t radius, 
                               slong prec );

void _compApp_poly_parallel_taylor_inplace( compApp_poly_t p, const compApp_t c, const realRat_t radius, slong prec, slong num_threads);
void compApp_poly_parallel_taylor_inplace( compApp_poly_t p, const realRat_t creal, const realRat_t cimag, const realRat_t radius, slong prec, slong num_threads);
void compApp_poly_parallel_taylor( compApp_poly_t dest, const compApp_poly_t p, const realRat_t creal, const realRat_t cimag, const realRat_t radius, slong prec, slong num_threads);

void compApp_poly_parallel_taylor_convol(compApp_poly_t dest, const compApp_poly_t p, const compApp_t c, const realRat_t radius, slong prec, slong num_threads);

#ifdef __cplusplus
}
#endif

#endif
