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

#ifndef CCLUSTER_H
#define CCLUSTER_H

#include "base/base.h"
#include "geometry/compBox.h"
#include "geometry/box_dsk.h"
#include "geometry/connCmp.h"
#include "geometry/connCmp_dsk.h"
#include "geometry/subdBox.h"
#include "geometry/connCmp_union_find.h"
#include "caches/cacheApp.h"
#include "metadatas/chronos.h"
#include "metadatas/metadatas.h"
#include "lists/compBox_list.h"
#include "lists/connCmp_list.h"
#include "tstar/tstar.h"
#include "newton/newton.h"
#include "powerSums/powerSums.h"


#ifdef CCLUSTER_HAVE_PTHREAD
#include "ccluster/parallel_discard.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

slong ccluster_discard_compBox_list( compBox_list_t boxes, cacheApp_t cache, 
//                                      int nbSols, 
                                     slong prec, metadatas_t meta);

void ccluster_bisect_connCmp( connCmp_list_t dest, 
                              connCmp_t cc, 
                              connCmp_list_t discardedCcs, 
                              cacheApp_t cache, 
                              metadatas_t meta, 
                              slong nbThreads);  

void ccluster_prep_loop( connCmp_list_t qMainLoop, 
                         connCmp_list_t qPrepLoop, 
                         connCmp_list_t discardedCcs, 
                         cacheApp_t cache, 
                         metadatas_t meta);

int  ccluster_compDsk_is_separated( const compDsk_t d, 
                                    connCmp_list_t qMainLoop, 
                                    connCmp_list_t discardedCcs );

void ccluster_main_loop( connCmp_list_t qResults,  
                         connCmp_list_t qMainLoop, 
                         connCmp_list_t discardedCcs, 
                         const realRat_t eps, 
                         cacheApp_t cache, 
                         metadatas_t meta);

void ccluster_algo( connCmp_list_t qResults, 
                    const compBox_t initialBox, 
                    const realRat_t eps, 
                    cacheApp_t cache, 
                    metadatas_t meta);

void ccluster_refine( connCmp_list_t qResults, 
                      connCmp_list_t qMainLoop,
                      const realRat_t eps, 
                      cacheApp_t cache, 
                      metadatas_t meta);

void connCmp_print_for_results(FILE * f, 
                               const connCmp_t c, 
                               metadatas_t meta);

void connCmp_list_print_for_results(FILE * f, 
                                    const connCmp_list_t c, 
                                    metadatas_t meta);

/* default interface */

// void ccluster_interface_func( void(*func)(compApp_poly_t, slong), 
//                               const compBox_t initialBox, 
//                               const realRat_t eps, 
//                               int st, 
//                               int verb);
void ccluster_interface_func( void(*func)(compApp_poly_t, slong), 
                              const compBox_t initialBox, 
                              const realRat_t eps, 
//                               int st,
                              char * stratstr,
                              int nbThreads,
                              int verb);

/* interfaces for Singular */

int ccluster_interface_poly( realRat_t * centerRe, realRat_t * centerIm, int * mults,
                             const compRat_poly_t poly, 
                             const compBox_t initialBox, 
                             const realRat_t eps, 
                             int st, 
                             int verb);

int ccluster_interface_poly_real( realRat_t * centerRe, realRat_t * centerIm, int * mults,
                                  const realRat_poly_t poly, 
                                  const realRat_t initialBox_cr, const realRat_t initialBox_ci, const realRat_t initialBox_wi,
                                  const realRat_t eps, 
                                  int st, 
                                  int verb);

int ccluster_interface_poly_real_imag( realRat_t * centerRe, realRat_t * centerIm, int * mults,
                                       const realRat_poly_t poly_real, const realRat_poly_t poly_imag,
                                       const realRat_t initialBox_cr, const realRat_t initialBox_ci, const realRat_t initialBox_wi,
                                       const realRat_t eps, 
                                       int st, 
                                       int verb);

/* interfaces for Julia */

void ccluster_interface_forJulia( connCmp_list_t qResults, 
                                  void(*func)(compApp_poly_t, slong), 
                                  const compBox_t initialBox, 
                                  const realRat_t eps, 
                                  int st, 
                                  int verb);

void ccluster_interface_forJulia_realRat_poly( connCmp_list_t qResults, 
                                              const realRat_poly_t poly, 
                                              const compBox_t initialBox, 
                                              const realRat_t eps, 
                                              int st, 
                                              int verb);

void ccluster_interface_forJulia_realRat_poly_real_imag( connCmp_list_t qResults, 
                                                         const realRat_poly_t poly_real, const realRat_poly_t poly_imag, 
                                                         const compBox_t initialBox, 
                                                         const realRat_t eps, 
                                                         int st, 
                                                         int verb);

void ccluster_interface_forJulia_compRat_poly( connCmp_list_t qResults, 
                                              const compRat_poly_t poly,
                                              const compBox_t initialBox, 
                                              const realRat_t eps, 
                                              int st, 
                                              int verb);

void ccluster_refine_forJulia( connCmp_list_t qResults,
                               connCmp_list_t qMainLoop,
                                  void(*func)(compApp_poly_t, slong), 
                                  const compBox_t initialBox, 
                                  const realRat_t eps, 
                                  int st, 
                                  int verb);

///implemented in ccluster_draw.c
void ccluster_interface_forJulia_draw( connCmp_list_t qResults, connCmp_list_t qDiscarded, 
                                  void(*func)(compApp_poly_t, slong), 
                                  const compBox_t initialBox, 
                                  const realRat_t eps, 
                                  int st, 
                                  int verb);

#ifdef __cplusplus
}
#endif

#endif
