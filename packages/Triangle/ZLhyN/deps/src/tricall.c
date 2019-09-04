#include "tricall.h"

void call_triangulate(char *triswitches, struct triangulateio *in, struct triangulateio *out, struct triangulateio *vorout) {
    triangulate(triswitches,in,out,vorout);
}

void call_trifree(VOID *memptr) {
    trifree(memptr);
}