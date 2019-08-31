/* ************************************************************************** */
/*  Copyright (C) 2019 Remi Imbach                                            */
/*                                                                            */
/*  This file is part of Ccluster.                                            */
/*                                                                            */
/*  Ccluster is free software: you can redistribute it and/or modify it under */
/*  the terms of the GNU Lesser General Public License (LGPL) as published    */
/*  by the Free Software Foundation; either version 2.1 of the License, or    */
/*  (at your option) any later version.  See <http://www.gnu.org/licenses/>.  */
/* ************************************************************************** */

#ifndef POWERSUMS_H
#define POWERSUMS_H

#include "base/base.h"
#include "numbers/realRat.h"
#include "numbers/realApp.h"
#include "numbers/app_rat.h"
#include "caches/cacheApp.h"
#include "metadatas/metadatas.h"

#include "acb_poly.h"

#ifdef __cplusplus
extern "C" {
#endif
    
slong powerSums_getNbOfPointsForCounting( const realRat_t wantedPrec, slong degree, const realRat_t isoRatio );

void powerSums_getEvaluationPoints( compApp_ptr points, 
                                    compApp_ptr pointsShifted,
                                    const compRat_t center,
                                    const realRat_t radius,
                                    slong nbPoints,
                                    slong prec );

void powerSums_evaluateAtPoints( compApp_ptr f_val,
                                 compApp_ptr fder_val,
                                 const compApp_ptr points,
                                 slong nbPoints,
                                 cacheApp_t cache,
                                 slong prec );

void powerSums_computeS0_fromVals( compApp_t s0, 
                                   compApp_ptr points,
                                   compApp_ptr f_val,
                                   compApp_ptr fder_val,
                                   slong nbPoints,
                                   slong prec );

void powerSums_computeS0_prec(     compApp_t s0, 
                                   compApp_ptr points,
                                   compApp_ptr pointsShifted,
                                   compApp_ptr f_val,
                                   compApp_ptr fder_val,
                                   const compRat_t center,
                                   const realRat_t radius,
                                   cacheApp_t cache,
                                   slong nbPoints,
                                   slong prec,
                                   metadatas_t meta, int depth);

typedef struct {
    int nbOfSol;   /* the number of solutions: -1: can not decide, >=0 otherwise */
    slong appPrec; /* the arithmetic precision that has been used to decide      */
} powerSums_res;

powerSums_res powerSums_countingTest( const compRat_t center,
                                      const realRat_t radius,
                                      cacheApp_t cache,
                                      slong nbPoints,
                                      slong prec,
                                      metadatas_t meta, int depth);

powerSums_res powerSums_countingTest_with_isoRatio( const compRat_t center,
                                                    const realRat_t radius,
                                                    cacheApp_t cache,
                                                    const realRat_t isoRatio,
                                                    slong prec );

#ifdef __cplusplus
}
#endif

#endif
