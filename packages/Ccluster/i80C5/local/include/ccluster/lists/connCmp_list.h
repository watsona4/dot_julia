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

#ifndef CONNCMP_LIST_H
#define CONNCMP_LIST_H

#ifdef LISTS_INLINE_C
#define LISTS_INLINE
#else
#define LISTS_INLINE static __inline__
#endif

#include "geometry/connCmp.h"
#include "lists/gen_list.h"

typedef struct gen_list connCmp_list;
typedef struct gen_list connCmp_list_t[1];
typedef struct gen_list * connCmp_list_ptr;

LISTS_INLINE void connCmp_clear_for_list(void * b){
    connCmp_clear( (connCmp_ptr) b );
}

LISTS_INLINE int connCmp_isless_for_list(const void * b1, const void * b2){
    
//     int res = connCmp_cmp_infIm ( (connCmp_ptr) b1, (connCmp_ptr) b2 );
//     
//     if (res == 0)
// //         return connCmp_isless_bs( (connCmp_ptr) b1, (connCmp_ptr) b2 );
//         return connCmp_isless( (connCmp_ptr) b1, (connCmp_ptr) b2 );
//     else
//         return res > 0;
    
    return connCmp_isless( (connCmp_ptr) b1, (connCmp_ptr) b2 );
}

LISTS_INLINE int connCmp_isgreater_for_list(const void * b1, const void * b2){
    return connCmp_isgreater( (connCmp_ptr) b1, (connCmp_ptr) b2 );
}

LISTS_INLINE int connCmp_isless_for_list_b(const void * b1, const void * b2){
    return connCmp_isless_b( (connCmp_ptr) b1, (connCmp_ptr) b2 );
}

LISTS_INLINE int connCmp_isgreater_for_list_b(const void * b1, const void * b2){
    return connCmp_isgreater_b( (connCmp_ptr) b1, (connCmp_ptr) b2 );
}

LISTS_INLINE void connCmp_fprint_for_list(FILE * file, const void * b){
    connCmp_fprint(file, (connCmp_ptr) b);
}

LISTS_INLINE void connCmp_list_init(connCmp_list_t l){
    gen_list_init(l, connCmp_clear_for_list);
}

LISTS_INLINE void connCmp_list_swap(connCmp_list_t l1, connCmp_list_t l2) {
    gen_list_swap(l1, l2);
}

LISTS_INLINE void connCmp_list_clear(connCmp_list_t l) {
    gen_list_clear(l);
}

LISTS_INLINE void connCmp_list_clear_for_tables(connCmp_list_t l) {
    gen_list_clear_for_tables(l);
}

LISTS_INLINE void connCmp_list_push(connCmp_list_t l, connCmp_ptr b){
    gen_list_push(l, b);
}

LISTS_INLINE connCmp_ptr connCmp_list_pop(connCmp_list_t l){
    return (connCmp_ptr) gen_list_pop(l);
}

LISTS_INLINE connCmp_ptr connCmp_list_first(connCmp_list_t l){
    return (connCmp_ptr) gen_list_first(l);
}

/* do not check bound!!! */
LISTS_INLINE connCmp_ptr connCmp_list_connCmp_at_index(connCmp_list_t l, int index){
    return (connCmp_ptr) gen_list_data_at_index(l, index);
}

LISTS_INLINE void connCmp_list_insert_sorted(connCmp_list_t l, connCmp_ptr b){
//     gen_list_insert_sorted(l, b, connCmp_isless_for_list);
    gen_list_insert_sorted(l, b, connCmp_isgreater_for_list);
}

LISTS_INLINE void connCmp_list_insert_sorted_b(connCmp_list_t l, connCmp_ptr b){
//     gen_list_insert_sorted(l, b, connCmp_isless_for_list);
    gen_list_insert_sorted(l, b, connCmp_isgreater_for_list_b);
}

LISTS_INLINE void connCmp_list_insert_sorted_inv(connCmp_list_t l, connCmp_ptr b){
    gen_list_insert_sorted(l, b, connCmp_isless_for_list);
//     gen_list_insert_sorted(l, b, connCmp_isgreater_for_list);
}

LISTS_INLINE void connCmp_list_fprint(FILE * file, const connCmp_list_t l){
    gen_list_fprint(file, l, connCmp_fprint_for_list);
}

LISTS_INLINE void connCmp_list_print(const connCmp_list_t l){
    connCmp_list_fprint(stdout, l);
}

LISTS_INLINE int connCmp_list_is_empty(const connCmp_list_t l){
    return gen_list_is_empty(l);
}
LISTS_INLINE int connCmp_list_get_size(const connCmp_list_t l){
    return gen_list_get_size(l);
}

/*iterator */
typedef gen_list_iterator connCmp_list_iterator;
LISTS_INLINE connCmp_list_iterator connCmp_list_begin(const connCmp_list_t l){
    return gen_list_begin(l);
}
LISTS_INLINE connCmp_list_iterator connCmp_list_next(connCmp_list_iterator it){
    return gen_list_next(it);
}
LISTS_INLINE connCmp_list_iterator connCmp_list_end(){
    return gen_list_end();
}
LISTS_INLINE connCmp_ptr connCmp_list_elmt(connCmp_list_iterator it){
    return (connCmp_ptr) gen_list_elmt(it);
}

#endif
