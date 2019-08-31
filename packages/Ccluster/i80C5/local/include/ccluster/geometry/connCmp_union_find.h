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

#ifndef CONNCMP_UNION_H
#define CONNCMP_UNION_H

#include "geometry/compBox.h"
#include "geometry/connCmp.h"
#include "lists/connCmp_list.h"

#ifdef __cplusplus
extern "C" {
#endif
    
void connCmp_union_compBox( connCmp_list_t ccs, compBox_t b);

#ifdef __cplusplus
}
#endif

#endif
