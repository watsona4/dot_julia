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

#ifndef CONNCMP_DSK_H
#define CONNCMP_DSK_H

#include "geometry/connCmp.h"
#include "geometry/compDsk.h"
#include "geometry/box_dsk.h"

#ifdef __cplusplus
extern "C" {
#endif
    
/*Precondition:                                                   */
/*Specification: returns true if interior(cc \cap b)\neq \emptyset*/ 
/*                       false otherwise                          */
int connCmp_intersection_has_non_empty_interior_compDsk( const connCmp_t cc, const compDsk_t d );

/*Precondition:                                            */
/*Specification: returns true if (cc \cap b)\neq \emptyset */
/*                       false otherwise                   */
/*               boxes of cc and b have not necessarily the same width */
int connCmp_intersection_is_not_empty_compDsk( const connCmp_t cc, const compDsk_t d );

#ifdef __cplusplus
}
#endif

#endif
