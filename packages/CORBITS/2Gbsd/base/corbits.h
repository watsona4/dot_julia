#include <cstdio>
#include "transit.h"
#define MAX 20
#define NFIELDS 8

// read a a list of exoplanet parameters from a file
bool read(FILE* fin, int &len, input_orbit io[]);
