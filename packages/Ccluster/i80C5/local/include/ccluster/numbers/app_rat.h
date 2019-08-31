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

#ifndef APPRAT_H
#define APPRAT_H

#ifdef NUMBERS_INLINE_C
#define NUMBERS_INLINE
#else
#define NUMBERS_INLINE static __inline__
#endif

#include "realRat.h"
#include "compRat.h"
#include "realApp.h"
#include "compApp.h"

#include "flint/fmpz.h"

#ifdef __cplusplus
extern "C" {
#endif

/* converting realRat to realApp */
NUMBERS_INLINE void realApp_set_realRat( realApp_t x, const realRat_t y, slong prec ) { arb_set_fmpq (x, y, prec); }

/* converting compRat to compApp */
NUMBERS_INLINE void compApp_set_compRat( compApp_t x, const compRat_t y, slong prec ) { 
    arb_set_fmpq( acb_realref(x), compRat_realref(y), prec);
    arb_set_fmpq( acb_imagref(x), compRat_imagref(y), prec);
}

NUMBERS_INLINE void compApp_set_realRat( compApp_t x, const realRat_t y, slong prec ) { 
    arb_set_fmpq( acb_realref(x), y, prec);
    arb_zero( acb_imagref(x));
}

NUMBERS_INLINE void compApp_setreal_realRat( compApp_t x, const realRat_t y, slong prec ) { 
    arb_set_fmpq( acb_realref(x), y, prec);
}

NUMBERS_INLINE void compApp_setimag_realRat( compApp_t x, const realRat_t y, slong prec ) { 
    arb_set_fmpq( acb_imagref(x), y, prec);
}

/*converts a disk to a compApp*/
void compApp_set_compDsk( compApp_t res, const compRat_t center, const realRat_t radius, slong prec);

/*getting a realRat lying in the ball defined by a realApp */
void realApp_get_realRat( realRat_t res, realApp_t x);
/*getting a compRat lying in the ball defined by a compApp */
NUMBERS_INLINE void compApp_get_compRat( compRat_t res, compApp_t x){
    realApp_get_realRat( compRat_realref(res), compApp_realref(x));
    realApp_get_realRat( compRat_imagref(res), compApp_imagref(x));
}

/* arithmetic */
void realApp_mul_realRat( realApp_t x, const realApp_t y, const realRat_t z, slong prec );
void compApp_mul_realRat( compApp_t x, const compApp_t y, const realRat_t z, slong prec );
void compApp_mul_realRat_in_place( compApp_t x, const realRat_t y, slong prec );

void compApp_mul_compRat( compApp_t x, const compApp_t y, const compRat_t z, slong prec );

#ifdef __cplusplus
}
#endif

#endif
