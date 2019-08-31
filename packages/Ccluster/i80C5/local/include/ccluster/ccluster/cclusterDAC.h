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

#ifndef CCLUSTER_DAC_H
#define CCLUSTER_DAC_H

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

#include "ccluster/ccluster.h" 

#ifdef __cplusplus
extern "C" {
#endif

int  ccluster_compDsk_is_separated_DAC( const compDsk_t d, 
                                        connCmp_list_t qMainLoop, 
                                        connCmp_list_t qResults,
                                        connCmp_list_t qAllResults, 
                                        connCmp_list_t discardedCcs );

void ccluster_prep_loop_DAC( connCmp_list_t qMainLoop, 
                             connCmp_list_t qPrepLoop, 
                             connCmp_list_t discardedCcs,
                             cacheApp_t cache, 
                             metadatas_t meta);

void ccluster_main_loop_DAC( connCmp_list_t qResults,
                             connCmp_list_t qAllResults,
                             connCmp_list_t qMainLoop, 
                             connCmp_list_t discardedCcs, 
                             int nbSols,
                             const realRat_t eps, 
                             cacheApp_t cache, 
                             metadatas_t meta);

void ccluster_DAC_first( connCmp_list_t qResults, 
                         connCmp_list_t qAllResults,
                         connCmp_list_t qMainLoop,
                         connCmp_list_t discardedCcs,
                         int nbSols,
                         const compBox_t initialBox, 
                         const realRat_t eps, 
                         cacheApp_t cache, 
                         metadatas_t meta);

void ccluster_DAC_next( connCmp_list_t qResults, 
                        connCmp_list_t qAllResults,
                        connCmp_list_t qMainLoop,
                        connCmp_list_t discardedCcs,
                        int nbSols,
                        const realRat_t eps, 
                        cacheApp_t cache, 
                        metadatas_t meta);

void ccluster_DAC_interface_forJulia( connCmp_list_t qResults, 
                                      connCmp_list_t qMainLoop,
                                      connCmp_list_t discardedCcs,
                                      void(*func)(compApp_poly_t, slong), 
                                      const compBox_t initialBox, 
                                      const realRat_t eps, 
                                      int st, 
                                      int verb);

void ccluster_DAC_next_interface_forJulia( connCmp_list_t qResults, 
                                           connCmp_list_t qAllResults,
                                           connCmp_list_t qMainLoop,
                                           connCmp_list_t discardedCcs,
                                           void(*func)(compApp_poly_t, slong), 
                                           int nbSols,
                                           const compBox_t initialBox, 
                                           const realRat_t eps, 
                                           int st, 
                                           int verb);

void ccluster_DAC_first_interface_forJulia( connCmp_list_t qResults, 
                                            connCmp_list_t qAllResults,
                                            connCmp_list_t qMainLoop,
                                            connCmp_list_t discardedCcs,
                                            void(*func)(compApp_poly_t, slong), 
                                            int nbSols,
                                            const compBox_t initialBox, 
                                            const realRat_t eps, 
                                            int st, 
                                            int verb);

// void ccluster_DAC_first_interface_func( void(*func)(compApp_poly_t, slong), const compBox_t initialBox, const realRat_t eps, int st, int verb);


#ifdef __cplusplus
}
#endif

#endif
