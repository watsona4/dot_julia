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

#ifndef CACHE_APP_H
#define CACHE_APP_H

#ifdef CACHE_INLINE_C
#define CACHE_INLINE
#else
#define CACHE_INLINE static __inline__
#endif

#include "base/base.h"
#include "numbers/compApp.h"
#include "polynomials/compRat_poly.h"
#include "polynomials/compApp_poly.h"
#include "polynomials/app_rat_poly.h"

#ifdef CCLUSTER_HAVE_PTHREAD
#include <pthread.h>
#endif

#define CACHE_DEFAULT_SIZE 10
// #define DEFAULT_PREC 53

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct {
    void(*_getApproximation)(compApp_poly_t, slong);
    compApp_poly_t *_cache;
    int _size;
    int _allocsize;
    
    compRat_poly_t _poly;
    int _from_poly;
#ifdef CCLUSTER_EXPERIMENTAL
    compApp_poly_t **_cache_der; /* a table of tables caching derivatives */
    int * _der_size;
#endif
    
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_t _mutex;
#endif
    /*for test: cache the last working polynomial computed and the nb of graeffe iterations*/
/*     compApp_poly _working;
       int _nbIterations; */
} cacheApp;

typedef cacheApp cacheApp_t[1];
typedef cacheApp * cacheApp_ptr;

CACHE_INLINE void cacheApp_lock(cacheApp_t cache) {
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_lock (&(cache->_mutex));
#endif
}

CACHE_INLINE void cacheApp_unlock(cacheApp_t cache) {
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_unlock (&(cache->_mutex));
#endif
}

/* #define cacheApp_workref(X) (&(X)->_working)    */
/* #define cacheApp_nbItref(X) (X->_nbIterations)  */

void cacheApp_init ( cacheApp_t cache, void(*getApproximation)(compApp_poly_t, slong) );

void cacheApp_init_compRat_poly ( cacheApp_t cache, const compRat_poly_t poly);
void cacheApp_init_realRat_poly ( cacheApp_t cache, const realRat_poly_t poly);

compApp_poly_ptr cacheApp_getApproximation ( cacheApp_t cache, slong prec );
slong cacheApp_getDegree ( cacheApp_t cache );
int cacheApp_is_real ( cacheApp_t cache );

#ifdef CCLUSTER_EXPERIMENTAL
compApp_poly_ptr cacheApp_getDerivative ( cacheApp_t cache, slong prec, slong order );
#endif

void cacheApp_clear ( cacheApp_t cache );

#ifdef __cplusplus
}
#endif

#endif
