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

#ifndef CHRONOS_H
#define CHRONOS_H

#ifdef METADATAS_INLINE_C
#define METADATAS_INLINE
#else
#define METADATAS_INLINE static __inline__
#endif

#include <time.h>
#ifdef CCLUSTER_HAVE_PTHREAD
#include <pthread.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct {
    /* DEPRECATED ?*/
//     clock_t _clicks_Approxi;
//     clock_t _clicks_Graeffe;
//     clock_t _clicks_Taylors;
//     clock_t _clicks_T0Tests;
//     clock_t _clicks_TSTests;
//     clock_t _clicks_Newtons;
//     clock_t _clicks_CclusAl;
//     clock_t _clicks_Derivat;
//     clock_t _clicks_Anticip;
//     clock_t _clicks_Evaluat;
    /* END DEPRECATED ?*/
    double  _clicks_Approxi_cumul;
    double  _clicks_Graeffe_cumul;
    double  _clicks_Taylors_cumul;
    double  _clicks_T0Tests_cumul;
    double  _clicks_TSTests_cumul;
    double  _clicks_Newtons_cumul;
    double  _clicks_CclusAl_cumul;
    double  _clicks_Derivat_cumul;
    double  _clicks_Anticip_cumul;
    /* for powerSums */
    double  _clicks_Evaluat_cumul;
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_t _mutex;
#endif    
} chronos;

typedef chronos chronos_t[1];
typedef chronos * chronos_ptr;
    
void chronos_init( chronos_t times );
void chronos_clear( chronos_t times );

// void chronos_join ( chronos_t t1, const chronos_t t2 );
METADATAS_INLINE void chronos_lock(chronos_t t){
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_lock (&(t->_mutex));
#endif
}

METADATAS_INLINE void chronos_unlock(chronos_t t){
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_unlock (&(t->_mutex));
#endif
}

METADATAS_INLINE void   chronos_add_time_Approxi( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_Approxi_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_Approxi_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_Approxi_cumul += d/CLOCKS_PER_SEC;
// #endif
}

METADATAS_INLINE void   chronos_add_time_Taylors( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_Taylors_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_Taylors_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_Taylors_cumul += d/CLOCKS_PER_SEC;
// #endif
}
METADATAS_INLINE void   chronos_add_time_Graeffe( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_Graeffe_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_Graeffe_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_Graeffe_cumul += d/CLOCKS_PER_SEC;
// #endif
}
METADATAS_INLINE void   chronos_add_time_T0Tests( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_T0Tests_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_T0Tests_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_T0Tests_cumul += d/CLOCKS_PER_SEC;
// #endif
}
METADATAS_INLINE void   chronos_add_time_TSTests( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_TSTests_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_TSTests_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_TSTests_cumul += d/CLOCKS_PER_SEC;
// #endif
}
METADATAS_INLINE void   chronos_add_time_Anticip( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_Anticip_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_Anticip_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_Anticip_cumul += d/CLOCKS_PER_SEC;
// #endif
}

METADATAS_INLINE void   chronos_add_time_Newtons( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_Newtons_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_Newtons_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_Newtons_cumul += d/CLOCKS_PER_SEC;
// #endif
}

METADATAS_INLINE void   chronos_add_time_Evaluat( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_Evaluat_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_Evaluat_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_Evaluat_cumul += d/CLOCKS_PER_SEC;
// #endif
}

METADATAS_INLINE void   chronos_add_time_CclusAl( chronos_t times, double d, int nbThreads ){
// #ifdef CCLUSTER_HAVE_PTHREAD
//     if (nbThreads>1)
//         times->_clicks_CclusAl_cumul += d/(nbThreads*CLOCKS_PER_SEC);
//     else 
//         times->_clicks_CclusAl_cumul += d/CLOCKS_PER_SEC;
// #else
    times->_clicks_CclusAl_cumul += d/CLOCKS_PER_SEC;
// #endif
}

METADATAS_INLINE double chronos_get_time_Approxi ( const chronos_t times ) { return times->_clicks_Approxi_cumul; }
METADATAS_INLINE double chronos_get_time_Graeffe ( const chronos_t times ) { return times->_clicks_Graeffe_cumul; }
METADATAS_INLINE double chronos_get_time_Taylors ( const chronos_t times ) { return times->_clicks_Taylors_cumul; }
METADATAS_INLINE double chronos_get_time_T0Tests ( const chronos_t times ) { return times->_clicks_T0Tests_cumul; }
METADATAS_INLINE double chronos_get_time_TSTests ( const chronos_t times ) { return times->_clicks_TSTests_cumul; }
METADATAS_INLINE double chronos_get_time_Newtons ( const chronos_t times ) { return times->_clicks_Newtons_cumul; }
METADATAS_INLINE double chronos_get_time_CclusAl ( const chronos_t times ) { return times->_clicks_CclusAl_cumul; }
METADATAS_INLINE double chronos_get_time_Evaluat ( const chronos_t times ) { return times->_clicks_Evaluat_cumul; }
METADATAS_INLINE double chronos_get_time_Derivat ( const chronos_t times ) { return times->_clicks_Derivat_cumul; }
METADATAS_INLINE double chronos_get_time_Anticip ( const chronos_t times ) { return times->_clicks_Anticip_cumul; }


/* DEPRECATED */
// METADATAS_INLINE void   chronos_tic_Approxi      ( chronos_t times ) { times->_clicks_Approxi = clock(); }
// METADATAS_INLINE void   chronos_toc_Approxi      ( chronos_t times ) { times->_clicks_Approxi_cumul += ((double) (clock() - times->_clicks_Approxi))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_Graeffe      ( chronos_t times ) { times->_clicks_Graeffe = clock(); }
// METADATAS_INLINE void   chronos_toc_Graeffe      ( chronos_t times ) { times->_clicks_Graeffe_cumul += ((double) (clock() - times->_clicks_Graeffe))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_Taylors      ( chronos_t times ) { times->_clicks_Taylors = clock(); }
// METADATAS_INLINE void   chronos_toc_Taylors      ( chronos_t times ) { times->_clicks_Taylors_cumul += ((double) (clock() - times->_clicks_Taylors))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_T0Tests      ( chronos_t times ) { times->_clicks_T0Tests = clock(); }
// METADATAS_INLINE void   chronos_toc_T0Tests      ( chronos_t times ) { times->_clicks_T0Tests_cumul += ((double) (clock() - times->_clicks_T0Tests))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_TSTests      ( chronos_t times ) { times->_clicks_TSTests = clock(); }
// METADATAS_INLINE void   chronos_toc_TSTests      ( chronos_t times ) { times->_clicks_TSTests_cumul += ((double) (clock() - times->_clicks_TSTests))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_Newtons      ( chronos_t times ) { times->_clicks_Newtons = clock(); }
// METADATAS_INLINE void   chronos_toc_Newtons      ( chronos_t times ) { times->_clicks_Newtons_cumul += ((double) (clock() - times->_clicks_Newtons))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_CclusAl      ( chronos_t times ) { times->_clicks_CclusAl = clock(); }
// METADATAS_INLINE void   chronos_toc_CclusAl      ( chronos_t times ) { times->_clicks_CclusAl_cumul += ((double) (clock() - times->_clicks_CclusAl))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_Evaluat      ( chronos_t times ) { times->_clicks_Evaluat = clock(); }
// METADATAS_INLINE void   chronos_toc_Evaluat      ( chronos_t times ) { times->_clicks_Evaluat_cumul += ((double) (clock() - times->_clicks_Evaluat))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_Derivat      ( chronos_t times ) { times->_clicks_Derivat = clock(); }
// METADATAS_INLINE void   chronos_toc_Derivat      ( chronos_t times ) { times->_clicks_Derivat_cumul += ((double) (clock() - times->_clicks_Derivat))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_Anticip      ( chronos_t times ) { times->_clicks_Anticip = clock(); }
// METADATAS_INLINE void   chronos_toc_Anticip      ( chronos_t times ) { times->_clicks_Anticip_cumul += ((double) (clock() - times->_clicks_Anticip))/ CLOCKS_PER_SEC; }
// 
// 
// METADATAS_INLINE void   chronos_tic_Test      ( chronos_t times, int discard ) { 
//     if (discard) times->_clicks_T0Tests = clock(); 
//     else         times->_clicks_TSTests = clock();
// }
// 
// METADATAS_INLINE void   chronos_toc_Test      ( chronos_t times, int discard ) { 
//     if (discard) times->_clicks_T0Tests_cumul += ((double) (clock() - times->_clicks_T0Tests))/ CLOCKS_PER_SEC;
//     else         times->_clicks_TSTests_cumul += ((double) (clock() - times->_clicks_TSTests))/ CLOCKS_PER_SEC;
// }


#ifdef __cplusplus
}
#endif

#endif
