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

#ifndef CONNCMP_H
#define CONNCMP_H

#ifdef GEOMETRY_INLINE_C
#define GEOMETRY_INLINE
#else
#define GEOMETRY_INLINE static __inline__
#endif

#include "base/base.h"
#include "numbers/realRat.h"
#include "geometry/compBox.h"
#include "lists/compBox_list.h"
#include "flint/fmpz.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    compBox_list boxes; /* a list of boxes                                */
    realRat      width; /* the width of boxes                             */
    realRat      infRe; /* the inf real bound                             */
    realRat      supRe; /* the sup real bound                             */
    realRat      infIm; /* the inf imag bound                             */
    realRat      supIm; /* the sup imag bound                             */
    int          nSols; /* the number of roots in the connected component */
    fmpz         nwSpd; /* the newton speed                               */
    slong        appPr; /* the number of bit of approximations            */
    int          newSu; /* a flag set to 1 iff the last newton iteration wa successful*/
    int          isSep; /* a flag set to 1 if the connected component is separated from the other ones*/
} connCmp;

typedef connCmp connCmp_t[1];
typedef connCmp * connCmp_ptr;

#define connCmp_boxesref(X) (&(X)->boxes)
#define connCmp_widthref(X) (&(X)->width)
#define connCmp_infReref(X) (&(X)->infRe)
#define connCmp_supReref(X) (&(X)->supRe)
#define connCmp_infImref(X) (&(X)->infIm)
#define connCmp_supImref(X) (&(X)->supIm)
#define connCmp_nSolsref(X) ( (X)->nSols)
#define connCmp_nwSpdref(X) (&(X)->nwSpd)
#define connCmp_appPrref(X) ( (X)->appPr)
#define connCmp_newSuref(X) ( (X)->newSu)
#define connCmp_isSepref(X) ( (X)->isSep)

/* memory managment */
void connCmp_init(connCmp_t x);
void connCmp_init_compBox(connCmp_t x, compBox_t b);

void connCmp_clear(connCmp_t x);
void connCmp_clear_for_tables(connCmp_t x);

/* deep copy of a connCmp; for the solver for triangular systems */
void connCmp_set(connCmp_t dest, const connCmp_t src);
/* allocate memory + deep copy; if called from C, need to deallocate the result */
connCmp_ptr connCmp_copy(connCmp_t src);

/* properties */
GEOMETRY_INLINE int connCmp_is_empty(const connCmp_t x){
    return compBox_list_is_empty(connCmp_boxesref(x));
}

GEOMETRY_INLINE int connCmp_nb_boxes(const connCmp_t x){
    return compBox_list_get_size(connCmp_boxesref(x));
}


GEOMETRY_INLINE void connCmp_width(realRat_t dest, connCmp_t x){
    realRat_set(dest, connCmp_widthref(x));
}


GEOMETRY_INLINE void connCmp_infRe(realRat_t dest, connCmp_t x){
    realRat_set(dest, connCmp_infReref(x));
}


GEOMETRY_INLINE void connCmp_supRe(realRat_t dest, connCmp_t x){
    realRat_set(dest, connCmp_supReref(x));
}


GEOMETRY_INLINE void connCmp_infIm(realRat_t dest, connCmp_t x){
    realRat_set(dest, connCmp_infImref(x));
}


GEOMETRY_INLINE void connCmp_supIm(realRat_t dest, connCmp_t x){
    realRat_set(dest, connCmp_supImref(x));
}

#define connCmp_nSols(X) ( (X)->nSols)
#define connCmp_appPr(X) ( (X)->appPr)
#define connCmp_newSu(X) ( (X)->newSu)
#define connCmp_isSep(X) ( (X)->isSep)

GEOMETRY_INLINE void connCmp_nwSpd(fmpz_t dest, connCmp_t x){
    fmpz_set(dest, connCmp_nwSpdref(x));
}

void connCmp_initiali_nwSpd(connCmp_t x);
void connCmp_initiali_nwSpd_connCmp(connCmp_t x, const connCmp_t src);
void connCmp_increase_nwSpd(connCmp_t x);
void connCmp_decrease_nwSpd(connCmp_t x);

slong connCmp_getDepth(const connCmp_t c, const compBox_t initialBox);

int connCmp_is_confined(const connCmp_t c, const compBox_t initialBox);

/* printing */
void connCmp_fprint(FILE * file, const connCmp_t x);

GEOMETRY_INLINE void connCmp_print(const connCmp_t x) {
    connCmp_fprint(stdout, x);
}

/* list operations */
/* maintains order in cc and hull */
void connCmp_insert_compBox(connCmp_t x, compBox_t b);

/* do not maintain connectedness nor hull */
GEOMETRY_INLINE compBox_ptr connCmp_pop(connCmp_t x) {
    return compBox_list_pop( connCmp_boxesref(x) );
}
/* do not maintain connectedness nor hull */
GEOMETRY_INLINE void connCmp_push(connCmp_t x, compBox_t b) {
    compBox_list_push( connCmp_boxesref(x), b );
}

/* do not check bound!!! */
GEOMETRY_INLINE compBox_ptr connCmp_compBox_at_index(connCmp_t x, int index) {
    return compBox_list_compBox_at_index( connCmp_boxesref(x), index );
}

/* Preconditions: cc1, cc2 are not empty, have the same width and are connected */
/* Specifs      : set cc1 to the union of cc1 and cc2 */
/*              : let cc2 empty but do not clear it   */
void connCmp_merge_2_connCmp( connCmp_t cc1, connCmp_t cc2 );

/* specifs      : define diam(cc) as the max of the width of the real part and the one of the imag part */
void connCmp_diameter( realRat_t diam, const connCmp_t cc);

/* ordering */
/* specifs      : cc1<=cc2 <=> diam(cc1)<=diam(cc2) */
int connCmp_isless ( const connCmp_t cc1, const connCmp_t cc2 );
int connCmp_isgreater ( const connCmp_t cc1, const connCmp_t cc2 );

GEOMETRY_INLINE int connCmp_isless_b ( const connCmp_t cc1, const connCmp_t cc2 ){
    return (connCmp_nb_boxes(cc1) < connCmp_nb_boxes(cc2));
}

GEOMETRY_INLINE int connCmp_isgreater_b ( const connCmp_t cc1, const connCmp_t cc2 ){
    return (connCmp_nb_boxes(cc1) > connCmp_nb_boxes(cc2));
}

GEOMETRY_INLINE int connCmp_isless_bs ( const connCmp_t cc1, const connCmp_t cc2 ){
    return (realRat_cmp( connCmp_widthref(cc1), connCmp_widthref(cc2) ) <= 0);
}

GEOMETRY_INLINE int connCmp_isgreater_bs ( const connCmp_t cc1, const connCmp_t cc2 ){
    return (realRat_cmp( connCmp_widthref(cc1), connCmp_widthref(cc2) ) >= 0);
}

GEOMETRY_INLINE int connCmp_isless_infIm ( const connCmp_t cc1, const connCmp_t cc2 ){
    return (realRat_cmp( connCmp_infImref(cc1), connCmp_infImref(cc2) ) <= 0);
}

GEOMETRY_INLINE int connCmp_isgreater_infIm ( const connCmp_t cc1, const connCmp_t cc2 ){
    return (realRat_cmp( connCmp_infImref(cc1), connCmp_infImref(cc2) ) >= 0);
}

GEOMETRY_INLINE int connCmp_cmp_infIm ( const connCmp_t cc1, const connCmp_t cc2 ){
    return realRat_cmp( connCmp_infImref(cc1), connCmp_infImref(cc2) );
}

void connCmp_componentBox( compBox_t res, const connCmp_t cc, const compBox_t initialBox);

/*Precondition:                                           */
/*Specification: returns true if each box of the cc is strictly in b   */
/*                       false otherwise                  */
int connCmp_is_strictly_in_compBox( const connCmp_t cc, const compBox_t b );

/*Precondition:                                                   */
/*Specification: returns true if interior(cc \cap b)\neq \emptyset*/ 
/*                       false otherwise                          */
int connCmp_intersection_has_non_empty_interior( const connCmp_t cc, const compBox_t b );

/*Precondition:                                            */
/*Specification: returns true if (cc \cap b)\neq \emptyset */
/*                       false otherwise                   */
/*               boxes of cc and b have not necessarily the same width */
int connCmp_intersection_is_not_empty( const connCmp_t cc, const compBox_t b );

/*Precondition:  boxes of cc and b HAVE the same width  */                               
/*Specification: returns true if (cc \cap b)\neq \emptyset */
/*                       false otherwise                   */
int connCmp_are_8connected( const connCmp_t cc, const compBox_t b );

void connCmp_find_point_outside_connCmp( compRat_t res, const connCmp_t cc, const compBox_t initialBox );

/* RealCoeffs */
/* Precondition:                                                                               */
/* Specification: returns true only if forall p\in cc, Im(p)<0                                 */
int connCmp_is_imaginary_negative_strict        ( const connCmp_t cc  );
/* Precondition:                                                                               */
/* Specification: returns true only if forall p\in cc, Im(p)>0                                 */
int connCmp_is_imaginary_positive_strict        ( const connCmp_t cc  );
/* Precondition:                                                                               */
/* Specification: returns true only if forall p\in cc, Im(p)>=0                                 */
int connCmp_is_imaginary_positive               ( const connCmp_t cc  );

/* Precondition: res is initialized                                                            */
/* Specification: set res to the complex conjugate of cc                                       */
void connCmp_set_conjugate                      ( connCmp_t res, const connCmp_t cc  );

void connCmp_set_conjugate_closure              ( connCmp_t res, const connCmp_t cc, const compBox_t initBox   );

/* DEPRECATED
void connCmp_find_point_outside_connCmp_for_julia( realRat_t resRe, realRat_t resIm, const connCmp_t cc, const compBox_t initialBox );
*/

#ifdef __cplusplus
}
#endif

#endif
