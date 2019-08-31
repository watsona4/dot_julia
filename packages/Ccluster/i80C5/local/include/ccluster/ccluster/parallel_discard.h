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

#ifndef PARALLEL_DISCARD_H
#define PARALLEL_DISCARD_H

#ifdef CCLUSTER_HAVE_PTHREAD

#include <pthread.h>

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

#ifdef __cplusplus
extern "C" {
#endif

    
typedef struct {
    slong prec;
    compBox_list_t boxes;
    cacheApp_ptr cache;
    metadatas_ptr meta;
//     int status; /* 0: default, 1: is_running, 2: is_finnished */
//     pthread_mutex_t mutex;
//     int * nb_thread_running;
//     pthread_mutex_t * mutex_nb_running;
} parallel_discard_list_arg_t;

void * _parallel_discard_list_worker( void * arg_ptr );

slong ccluster_parallel_discard_compBox_list( compBox_list_t boxes, cacheApp_t cache, 
                                        slong prec, metadatas_t meta, slong nbThreads);


/* DEPRECATED */  
// typedef struct {
//     connCmp_list_t res;
//     connCmp_ptr      cc;
//     connCmp_list_t dis;
//     cacheApp_ptr cache;
//     metadatas_ptr meta;
//     slong nbThreads;
//     int status; /* 0: default, 1: is_running, 2: is_finnished */
//     pthread_mutex_t mutex;
//     int * nb_thread_running;
//     pthread_mutex_t * mutex_nb_running;
// } parallel_bisect_arg_t;

// void * _parallel_bisect_worker( void * arg_ptr );
// void ccluster_parallel_bisect_connCmp_list( connCmp_list_ptr qMainLoop, connCmp_list_ptr discardedCcs,
//                                             connCmp_list_ptr toBeBisected, cacheApp_t cache, metadatas_t meta);
// 
// /* assume the boxes have already be quadrisected */
// void ccluster_bisect_connCmp_without_quadrisect( connCmp_list_t dest, 
//                                                  connCmp_t cc, 
//                                                  connCmp_list_t discardedCcs, 
//                                                  cacheApp_t cache, 
//                                                  metadatas_t meta, slong nbThreads);

#ifdef __cplusplus
}
#endif

#endif

#endif
