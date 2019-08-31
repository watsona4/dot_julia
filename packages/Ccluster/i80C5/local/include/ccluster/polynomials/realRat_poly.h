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

#ifndef REALRAT_POLY_H
#define REALRAT_POLY_H

#ifdef POLYNOMIALS_INLINE_C
#define POLYNOMIALS_INLINE
#else
#define POLYNOMIALS_INLINE static __inline__
#endif

#include "flint/fmpq_poly.h"
#include "flint/arith.h"
#include "numbers/realRat.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef fmpq_poly_struct realRat_poly;
typedef realRat_poly realRat_poly_t[1];
typedef realRat_poly * realRat_poly_ptr;

/* memory managment */
POLYNOMIALS_INLINE void realRat_poly_init      (realRat_poly_t poly)            { fmpq_poly_init      (poly);}
POLYNOMIALS_INLINE void realRat_poly_init2     (realRat_poly_t poly, slong len) { fmpq_poly_init2     (poly, len);}
POLYNOMIALS_INLINE void realRat_poly_clear     (realRat_poly_t poly)            { fmpq_poly_clear     (poly);}
POLYNOMIALS_INLINE void realRat_poly_fit_length(realRat_poly_t poly, slong len) { fmpq_poly_fit_length(poly, len); }

/* setting */
POLYNOMIALS_INLINE void realRat_poly_set (realRat_poly_t poly1, const realRat_poly_t poly2) {
    fmpq_poly_set(poly1, poly2);
}
POLYNOMIALS_INLINE void realRat_poly_zero(realRat_poly_t poly) {
    fmpq_poly_zero(poly);
}
POLYNOMIALS_INLINE void realRat_poly_one(realRat_poly_t poly) {
    fmpq_poly_one(poly);
}

/* getting elements */
POLYNOMIALS_INLINE slong realRat_poly_length(const realRat_poly_t poly) {
    return fmpq_poly_length(poly);
}
POLYNOMIALS_INLINE slong realRat_poly_degree(const realRat_poly_t poly) {
    return fmpq_poly_degree(poly);
}
POLYNOMIALS_INLINE void realRat_poly_get_coeff_realRat(realRat_t x, const realRat_poly_t poly, slong n) {
    fmpq_poly_get_coeff_fmpq(x, poly, n);
}
POLYNOMIALS_INLINE void realRat_poly_set_coeff_realRat(realRat_poly_t poly, slong n, const realRat_t x) {
    fmpq_poly_set_coeff_fmpq(poly, n, x);
}
POLYNOMIALS_INLINE void realRat_poly_set_coeff_si_ui(realRat_poly_t poly, slong n, slong num, ulong den) {
    realRat_t temp; 
    realRat_init( temp );
    realRat_set_si(temp, num, den);
    realRat_poly_set_coeff_realRat( poly, n, temp);
    realRat_clear(temp);
}

/*arithmetic operations */
POLYNOMIALS_INLINE void realRat_poly_pow(realRat_poly_t res, const realRat_poly_t poly, ulong e) {
    fmpq_poly_pow(res, poly, e);
}
POLYNOMIALS_INLINE void realRat_poly_neg(realRat_poly_t res, const realRat_poly_t poly) {
    fmpq_poly_neg(res, poly);
}
POLYNOMIALS_INLINE void realRat_poly_mul(realRat_poly_t res, const realRat_poly_t poly1, const realRat_poly_t poly2) {
    fmpq_poly_mul(res, poly1, poly2);
}
POLYNOMIALS_INLINE void realRat_poly_add(realRat_poly_t res, const realRat_poly_t poly1, const realRat_poly_t poly2) {
    fmpq_poly_add(res, poly1, poly2);
}
POLYNOMIALS_INLINE void realRat_poly_scalar_mul_realRat(realRat_poly_t res, const realRat_poly_t poly1, const realRat_t q) {
    fmpq_poly_scalar_mul_fmpq(res, poly1, q);
}

/* printing */
POLYNOMIALS_INLINE int realRat_poly_fprint       (FILE * file, const realRat_poly_t poly) { return fmpq_poly_fprint(file, poly);}
POLYNOMIALS_INLINE int realRat_poly_fprint_pretty(FILE * file, const realRat_poly_t poly, const char * var) {
    return fmpq_poly_fprint_pretty(file, poly, var);
}
POLYNOMIALS_INLINE int realRat_poly_print       (const realRat_poly_t poly) { return fmpq_poly_print(poly); }
POLYNOMIALS_INLINE int realRat_poly_print_pretty(const realRat_poly_t poly, const char * var) {
    return fmpq_poly_print_pretty(poly, var);
}

/*separation bound for integer polynomials*/
/* here we assume that the coefficients of the pol are interger! */
void realRat_poly_separationBound (realRat_t sep, const realRat_poly_t pol);
/*bitsize for integer polynomials*/
/* here we assume that the coefficients of the pol are interger! */
slong realRat_poly_bitsize (const realRat_poly_t pol);

/*special polynomials */
POLYNOMIALS_INLINE void bernoulli_polynomial( realRat_poly_t poly, slong deg) {
    arith_bernoulli_polynomial(poly , deg);
}
void mignotte_polynomial(realRat_poly_t poly, slong deg, slong bitsize);
void mignotte_generalized(realRat_poly_t poly, slong deg, ulong pow, slong bitsize);

#ifdef __cplusplus
}
#endif

#endif
