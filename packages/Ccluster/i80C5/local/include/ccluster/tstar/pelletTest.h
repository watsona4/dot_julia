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

#ifndef PELLET_TEST_H
#define PELLET_TEST_H

#include "numbers/realRat.h"
#include "numbers/realApp.h"
#include "numbers/compApp.h"
#include "numbers/app_rat.h"
#include "polynomials/compApp_poly.h"

#ifdef __cplusplus
extern "C" {
#endif
    
int realApp_soft_compare(const realApp_t a, const realApp_t b, slong prec);

int compApp_poly_TkGtilda_with_sum( const compApp_poly_t f, const realApp_t s, const ulong k, slong prec);

#ifdef __cplusplus
}
#endif

#endif
