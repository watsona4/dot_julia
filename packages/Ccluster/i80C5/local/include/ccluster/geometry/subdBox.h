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

#ifndef SUBDBOX_H
#define SUBDBOX_H

#include <stdio.h>
#include "base/base.h"
#include "geometry/compBox.h"
#include "geometry/compDsk.h"
#include "geometry/box_dsk.h"
#include "lists/compBox_list.h"
#include "flint/fmpz.h"
#include "flint/fmpq.h"

#ifdef __cplusplus
extern "C" {
#endif

void subdBox_quadrisect( compBox_list_t res, const compBox_t b );

void subdBox_quadrisect_with_compDsk( compBox_list_t res, const compBox_t b, const compDsk_t d, const realRat_t nwidth);

/*DEPRECATED 

void subdBox_quadrisect_intersect_compDsk( compBox_list_t res, const compBox_t b, const compDsk_t d);
*/

#ifdef __cplusplus
}
#endif

#endif
