#ifndef TRICALL_H
    // Stuff for triangle.h
	#include "commondefine.h"
    #include "triangle.h"

    extern DLLEXPORT void call_triangulate(char *, struct triangulateio *, struct triangulateio *, struct triangulateio *);
    extern DLLEXPORT void call_trifree(VOID *memptr);

    #define TRICALL_H 
#endif