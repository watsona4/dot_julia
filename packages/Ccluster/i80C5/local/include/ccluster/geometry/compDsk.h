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

#ifndef COMPDSK_H
#define COMPDSK_H

#ifdef GEOMETRY_INLINE_C
#define GEOMETRY_INLINE
#else
#define GEOMETRY_INLINE static __inline__
#endif

#include "numbers/realRat.h"
#include "numbers/compRat.h"

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct {
    compRat center;
    realRat radius;
} compDsk;

typedef compDsk compDsk_t[1];
typedef compDsk * compDsk_ptr;

#define compDsk_centerref(X) (&(X)->center)
#define compDsk_radiusref(X) (&(X)->radius)

/* memory managment */
GEOMETRY_INLINE void compDsk_init(compDsk_t x) { 
    compRat_init(compDsk_centerref(x)); 
    realRat_init(compDsk_radiusref(x));
}

GEOMETRY_INLINE void compDsk_clear(compDsk_t x) { 
    compRat_clear(compDsk_centerref(x)); 
    realRat_clear(compDsk_radiusref(x));
}

/* members access */
GEOMETRY_INLINE compRat_ptr compDsk_center_ptr(compDsk_t x) {
    return compDsk_centerref(x);
}

GEOMETRY_INLINE realRat_ptr compDsk_radius_ptr(compDsk_t x) {
    return compDsk_radiusref(x);
}

GEOMETRY_INLINE void compDsk_get_center(compRat_t c, const compDsk_t x) {
    compRat_set(c, compDsk_centerref(x));
}

GEOMETRY_INLINE void compDsk_get_centerRe(realRat_t c, const compDsk_t x) {
    realRat_set(c, compRat_realref(compDsk_centerref(x)));
}

GEOMETRY_INLINE void compDsk_get_centerIm(realRat_t c, const compDsk_t x) {
    realRat_set(c, compRat_imagref(compDsk_centerref(x)));
}

GEOMETRY_INLINE void compDsk_get_radius(realRat_t r, const compDsk_t x) {
    realRat_set(r, compDsk_radiusref(x));
}

/* printing */
void compDsk_fprint(FILE * file, const compDsk_t x);

GEOMETRY_INLINE void compDsk_print(const compDsk_t x) {
    compDsk_fprint(stdout, x);
}

/* setting */
GEOMETRY_INLINE void compDsk_set_3realRat(compDsk_t d, const realRat_t cr, const realRat_t ci, const realRat_t r){
    compRat_set_2realRat( compDsk_centerref(d), cr, ci);
    realRat_set( compDsk_radiusref(d), r);
}

GEOMETRY_INLINE void compDsk_set_compRat_realRat(compDsk_t d, const compRat_t c, const realRat_t r){
    compRat_set( compDsk_centerref(d), c);
    realRat_set( compDsk_radiusref(d), r);
}

GEOMETRY_INLINE void compDsk_set(compDsk_t d, const compDsk_t e){
    compRat_set( compDsk_centerref(d), compDsk_centerref(e));
    realRat_set( compDsk_radiusref(d), compDsk_radiusref(e));
}

/* Inflate */
/*acts in place*/
GEOMETRY_INLINE void compDsk_inflate_realRat_inplace(compDsk_t d, const realRat_t f){
    realRat_mul( compDsk_radiusref(d), compDsk_radiusref(d), f );
}

void compDsk_inflate_realRat(compDsk_t d, const compDsk_t e, const realRat_t f);

/* geometric predicates */
int compDsk_is_point_in_dsk         ( const compRat_t p, const compDsk_t d);
int compDsk_is_point_strictly_in_dsk( const compRat_t p, const compDsk_t d);

/* RealCoeffs */
/* Precondition:                                                                               */
/* Specification: returns true only if forall p\in cc, Im(p)>0                                 */
int compDsk_is_imaginary_positive_strict        ( const compDsk_t d  );

#ifdef __cplusplus
}
#endif
    
#endif
