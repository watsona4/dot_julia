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

#ifndef BOX_DSK_H
#define BOX_DSK_H

#include "geometry/compBox.h"
#include "geometry/compDsk.h"

#ifdef __cplusplus
extern "C" {
#endif
    
slong compDsk_getDepth(const compDsk_t d, const compBox_t initialBox);

void compBox_get_containing_dsk( compDsk_t d, const compBox_t b);

/* geometric predicates */
/* Precondition:                                                                               */
/* Specification: returns true if (b \cap d)\neq \emptyset                                     */
/*                        false otherwise                                                      */
int compBox_intersection_is_not_empty_compDsk ( const compBox_t b, const compDsk_t d);

/* Precondition: width of b and radius of d are non-zero */                                                                           
/* Specification: returns true if interior(b \cap d)\neq \emptyset                             */
/*                        false otherwise                                                      */
int compBox_intersection_has_non_empty_interior_compDsk ( const compBox_t b, const compDsk_t d);

/* Precondition: b has non-nul width */
int compBox_is_box_in_dsk ( const compBox_t b, const compDsk_t d);

#ifdef __cplusplus
}
#endif

#endif
