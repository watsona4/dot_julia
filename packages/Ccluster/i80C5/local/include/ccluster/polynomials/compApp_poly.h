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

#ifndef COMPAPP_POLY_H
#define COMPAPP_POLY_H

#ifdef POLYNOMIALS_INLINE_C
#define POLYNOMIALS_INLINE
#else
#define POLYNOMIALS_INLINE static __inline__
#endif

#include "acb_poly.h"
#include "base/base.h"
#include "numbers/compApp.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef acb_poly_struct compApp_poly;
typedef acb_poly_struct compApp_poly_t[1];
typedef acb_poly_struct * compApp_poly_ptr;

/* memory managment */
POLYNOMIALS_INLINE void compApp_poly_init      (compApp_poly_t poly)            { acb_poly_init      (poly);}
POLYNOMIALS_INLINE void compApp_poly_init2     (compApp_poly_t poly, slong len) { acb_poly_init2     (poly, len);}
POLYNOMIALS_INLINE void compApp_poly_clear     (compApp_poly_t poly)            { acb_poly_clear     (poly);}
POLYNOMIALS_INLINE void compApp_poly_fit_length(compApp_poly_t poly, slong len) { acb_poly_fit_length(poly, len); }
POLYNOMIALS_INLINE void compApp_poly_set_length(compApp_poly_t poly, slong len) { _acb_poly_set_length(poly, len); }

POLYNOMIALS_INLINE slong compApp_poly_degree(const compApp_poly_t poly) { return acb_poly_degree(poly); }
/* bounds are not checked */
POLYNOMIALS_INLINE compApp_srcptr compApp_poly_getCoeff(const compApp_poly_t poly, slong degree) { return poly->coeffs + degree; }
POLYNOMIALS_INLINE void  compApp_poly_swap( compApp_poly_t poly1, compApp_poly_t poly2 ) { acb_poly_swap(poly1, poly2); }

/* printing */
POLYNOMIALS_INLINE void compApp_poly_fprintd(FILE * file, const compApp_poly_t poly, slong digits) {
    acb_poly_fprintd(file, poly, digits);
}
POLYNOMIALS_INLINE void compApp_poly_printd(const compApp_poly_t poly, slong digits) {
    acb_poly_printd(poly, digits);
}

/* accuracy */
int compApp_poly_checkAccuracy( const compApp_poly_t poly, slong prec);

slong compApp_poly_getAccuracy_min( const compApp_poly_t poly);
slong compApp_poly_getAccuracy_max( const compApp_poly_t poly);

/* setting */
POLYNOMIALS_INLINE void compApp_poly_zero(compApp_poly_t poly) { acb_poly_zero(poly); }
POLYNOMIALS_INLINE void compApp_poly_one (compApp_poly_t poly) { acb_poly_one (poly); }
POLYNOMIALS_INLINE void compApp_poly_set (compApp_poly_t dest, const compApp_poly_t src) { acb_poly_set (dest, src); }
POLYNOMIALS_INLINE void compApp_poly_set_coeff_si (compApp_poly_t dest, slong n, slong x)           { acb_poly_set_coeff_si (dest, n, x); }
POLYNOMIALS_INLINE void compApp_poly_set_coeff_compApp(compApp_poly_t dest, slong n, const compApp_t x) { acb_poly_set_coeff_acb(dest, n, x); }

POLYNOMIALS_INLINE void compApp_poly_set_fmpq_poly(compApp_poly_t poly, const fmpq_poly_t re, slong prec) {
    acb_poly_set_fmpq_poly(poly, re, prec);
}
POLYNOMIALS_INLINE void compApp_poly_set2_fmpq_poly(compApp_poly_t poly, const fmpq_poly_t re, const fmpq_poly_t im, slong prec) {
    acb_poly_set2_fmpq_poly(poly, re, im, prec);
}

/* rounding */
POLYNOMIALS_INLINE void compApp_poly_set_round(compApp_poly_t dest, const compApp_poly_t src, slong prec) { acb_poly_set_round( dest, src, prec); }

/* Comparisons */
POLYNOMIALS_INLINE int compApp_poly_is_real( const compApp_poly_t poly ) {
    return acb_poly_is_real(poly);
}
/* Arithmetic */
POLYNOMIALS_INLINE void compApp_poly_mul( compApp_poly_t res, const compApp_poly_t poly1, const compApp_poly_t poly2, slong prec) {
    acb_poly_mul (res, poly1, poly2, prec);
}
POLYNOMIALS_INLINE void compApp_poly_mullow( compApp_poly_t res, const compApp_poly_t poly1, const compApp_poly_t poly2, slong n, slong prec) {
    acb_poly_mullow (res, poly1, poly2, n, prec);
}
POLYNOMIALS_INLINE void compApp_poly_sub( compApp_poly_t res, const compApp_poly_t poly1, const compApp_poly_t poly2, slong prec) {
    acb_poly_sub (res, poly1, poly2, prec);
}
POLYNOMIALS_INLINE void compApp_poly_add( compApp_poly_t res, const compApp_poly_t poly1, const compApp_poly_t poly2, slong prec) {
    acb_poly_add (res, poly1, poly2, prec);
}
POLYNOMIALS_INLINE void compApp_poly_shift_left( compApp_poly_t res, const compApp_poly_t poly, slong n) {
    acb_poly_shift_left (res, poly, n);
}
POLYNOMIALS_INLINE void compApp_poly_neg( compApp_poly_t res, const compApp_poly_t poly) {
    acb_poly_neg (res, poly);
}

/* evaluation */
POLYNOMIALS_INLINE  void compApp_poly_evaluate(compApp_t y, const compApp_poly_t f, const compApp_t x, slong prec){
    acb_poly_evaluate_rectangular(y, f, x, prec);
}
POLYNOMIALS_INLINE  void compApp_poly_evaluate_horner(compApp_t y, const compApp_poly_t f, const compApp_t x, slong prec){
    acb_poly_evaluate_horner(y, f, x, prec);
}
POLYNOMIALS_INLINE  void compApp_poly_evaluate2(compApp_t y, compApp_t z, const compApp_poly_t f, const compApp_t x, slong prec){
    acb_poly_evaluate2_rectangular(y, z, f, x, prec);
}

POLYNOMIALS_INLINE  void compApp_poly_evaluate2_rectangular(compApp_t y, compApp_t z, const compApp_poly_t f, const compApp_t x, slong prec){
    acb_poly_evaluate2_rectangular(y, z, f, x, prec);
}

POLYNOMIALS_INLINE  void compApp_poly_evaluate2_horner(compApp_t y, compApp_t z, const compApp_poly_t f, const compApp_t x, slong prec){
    acb_poly_evaluate2_horner(y, z, f, x, prec);
}

/* derivation */
POLYNOMIALS_INLINE  void compApp_poly_derivative(compApp_poly_t fp, const compApp_poly_t f, slong prec){
    acb_poly_derivative(fp, f, prec);
}

/* sum absolute values of coeffs */
void compApp_poly_sum_abs_coeffs( realApp_t res, const compApp_poly_t f, slong prec );

/* taylor shift */
void compApp_poly_taylor_shift_conv_pre(compApp_poly_t dest, const compApp_poly_t p, realApp_t f, compApp_ptr t, slong prec);
void _compApp_poly_taylor_shift_convolution(compApp_ptr p, realApp_t f, compApp_ptr t, const compApp_t c, slong len, slong prec);
void compApp_poly_taylor_shift_convolution(compApp_poly_t g, const compApp_poly_t f, const compApp_t c, slong prec);

/* Graeffe iterations */
void compApp_poly_oneGraeffeIteration_coeff( compApp_ptr coeff, compApp_srcptr f, slong index, slong len, slong prec);
/* requires: f is a partially computed polynomial of degree len-1 */
/*           its coeffs from 0 to n + delta exist, where delta = min(n, len-1-n) */
void compApp_poly_oneGraeffeIteration_first_n_coeff( compApp_poly_t res, const compApp_poly_t f, slong n, slong len, slong prec);
/* requires: f is initialized */
void compApp_poly_oneGraeffeIteration_in_place( compApp_poly_t f, slong prec );

#ifdef __cplusplus
}
#endif

#endif

