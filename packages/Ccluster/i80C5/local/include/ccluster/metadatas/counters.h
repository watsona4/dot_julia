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

#ifndef COUNTERS_H
#define COUNTERS_H

#ifdef METADATAS_INLINE_C
#define METADATAS_INLINE
#else
#define METADATAS_INLINE static __inline__
#endif

#include <stdlib.h>
#include <string.h>
#include "base/base.h"

#ifdef CCLUSTER_HAVE_PTHREAD
#include <pthread.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define INIT_SIZE_STATS 1000
    
typedef struct {
        int size;
        int size_allocated;
        int *table;
#ifdef CCLUSTER_HAVE_PTHREAD
        pthread_mutex_t _mutex;
#endif
} boxes_by_prec; /* a stat is a table of counters by depth */

typedef boxes_by_prec boxes_by_prec_t[1];

void boxes_by_prec_init( boxes_by_prec_t bt );
void boxes_by_prec_clear( boxes_by_prec_t bt );
void boxes_by_prec_add_int( boxes_by_prec_t bt, slong prec, int nbBoxes );
void boxes_by_prec_add_boxes_by_prec( boxes_by_prec_t bt, boxes_by_prec_t t );
void boxes_by_prec_adjust_table( boxes_by_prec_t bt, int index );
int  boxes_by_prec_fprint( FILE * file, const boxes_by_prec_t bt );

typedef struct {
    int nbDiscarded; /*nb of boxes discarded*/
    int nbValidated; /*nb of clusters validated*/
    int nbSolutions;
    int nbExplored; /*nb of boxes explores*/
    /* T0Tests */
    int nbT0Tests;
    int nbFailingT0Tests;
    int nbGraeffeInT0Tests;
    int nbGraeffeRepetedInT0Tests;
    int nbTaylorsInT0Tests;
    int nbTaylorsRepetedInT0Tests;
    /* TSTests */
    int nbTSTests;
    int nbFailingTSTests;
    int nbGraeffeInTSTests;
    int nbGraeffeRepetedInTSTests;
    int nbTaylorsInTSTests;
    int nbTaylorsRepetedInTSTests;
    /* Newton steps */
    int nbNewton;
    int nbFailingNewton;
    /* Power Sums */
    int nbEval;
    int nbPsCountingTest;
    boxes_by_prec_t bpc;
} counters_by_depth;

typedef counters_by_depth counters_by_depth_t[1];
typedef counters_by_depth * counters_by_depth_ptr;

#define counters_by_depth_bpcref(x) (&(x)->bpc)

void counters_by_depth_init( counters_by_depth_t st);
METADATAS_INLINE void counters_by_depth_clear( counters_by_depth_t st) { boxes_by_prec_clear(st->bpc); }

typedef struct {
        int size;
        int size_allocated;
        counters_by_depth_ptr table;
        counters_by_depth_t total;
#ifdef CCLUSTER_HAVE_PTHREAD
        pthread_mutex_t _mutex;
#endif
} counters; /* a stat is a table of counters by depth */

typedef counters counters_t[1];

void counters_init( counters_t st);
void counters_clear( counters_t st);
void counters_adjust_table( counters_t st, int depth );

METADATAS_INLINE void counters_lock(counters_t t){
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_lock (&(t->_mutex));
#endif
}

METADATAS_INLINE void counters_unlock(counters_t t){
#ifdef CCLUSTER_HAVE_PTHREAD
    pthread_mutex_unlock (&(t->_mutex));
#endif
}

void counters_add_discarded( counters_t st, int depth );
void counters_add_validated( counters_t st, int depth, int nbSols );
void counters_add_explored ( counters_t st, int depth );
void counters_add_Test     ( counters_t st, int depth, int res, int discard, 
                             int nbTaylors, int nbTaylorsRepeted, 
                             int nbGraeffe, int nbGraeffeRepeted,
                             slong prec
                           );

void counters_add_Newton   ( counters_t st, int depth, int res );

void counters_count ( counters_t st );
int counters_getDepth( const counters_t st);

int counters_getNbDiscarded                 ( const counters_t st );
int counters_getNbValidated                 ( const counters_t st );
int counters_getNbExplored                  ( const counters_t st );
int counters_getNbSolutions                 ( const counters_t st );
int counters_getNbT0Tests                   ( const counters_t st );
int counters_getNbFailingT0Tests            ( const counters_t st );
int counters_getNbGraeffeInT0Tests          ( const counters_t st );
int counters_getNbGraeffeRepetedInT0Tests   ( const counters_t st );
int counters_getNbTaylorsInT0Tests          ( const counters_t st );
int counters_getNbTaylorsRepetedInT0Tests   ( const counters_t st );
int counters_getNbTSTests                   ( const counters_t st );
int counters_getNbFailingTSTests            ( const counters_t st );
int counters_getNbGraeffeInTSTests          ( const counters_t st );
int counters_getNbGraeffeRepetedInTSTests   ( const counters_t st );
int counters_getNbTaylorsInTSTests          ( const counters_t st );
int counters_getNbTaylorsRepetedInTSTests   ( const counters_t st );
int counters_getNbNewton                    ( const counters_t st );
int counters_getNbFailingNewton             ( const counters_t st );
int counters_getNbEval                      ( const counters_t st );
int counters_getNbPsCountingTest            ( const counters_t st );

void counters_add_Eval( counters_t st, int nbEvals, int depth );
void counters_add_PsCountingTest( counters_t st, int depth );

METADATAS_INLINE int counters_boxes_by_prec_fprint ( FILE * file, const counters_t st ) {
    return boxes_by_prec_fprint( file, st->total->bpc);
}

/* DEPRECATED */
// void counters_join_depth( counters_t c1, const counters_by_depth_t c2, int depth);
// void counters_join( counters_t c1, const counters_t c2);
// void counters_by_depth_join( counters_by_depth_t c1, const counters_by_depth_t c2);
/* void counters_by_depth_get_lenghts_of_str( counters_by_depth_t res, counters_by_depth_t st);*/
/* void counters_get_lenghts_of_str( counters_by_depth_t res, counters_by_depth_t st);*/

#ifdef __cplusplus
}
#endif

#endif
