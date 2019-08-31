// read data collected from the Exoplanet Archive
#include "koi_input.h"
#include <cstdio>
#include <cassert>
#include <cstring>
#include <cstdlib>
#include <cmath>

int input_data(const char* FILENAME, kepler_input kepler_data[NDATA]) {
  int ndata = 0;
  FILE *fin = fopen(FILENAME, "r");
  assert (fin != NULL);
  fprintf (stderr, "Loading ...\n");
  for (int i = 0; /*read until EOF*/; i++, ndata++) {
    int nread = 0;
    for (int j = 0; j < COLUMNS; j++) {
      char s[10] = "filler";
      if (fscanf (fin, "%s", s) == EOF) break;
      // fprintf(stderr, "%s\n", s);
      if (j == 0)
	kepler_data[i].KIC = atoi(s);
      else if (j == 1)
	kepler_data[i].KOI = atof(s + 1);
      else if (j == 2)
	kepler_data[i].Per  = atof(s);
      else if (j == 3)
	kepler_data[i].e_Per = atof (s);
      else if (j == 4)
	kepler_data[i].b = atof(s);
      else if (j == 5)
	kepler_data[i].e_b = atof(s);
      else if (j == 6)
	kepler_data[i].i = atof(s);
      else if (j == 7)
	kepler_data[i].a  = atof(s);
      else if (j == 8)
	kepler_data[i].d_R = atof(s);
      else if (j == 9)
	kepler_data[i].r_R = atof(s);
      else if (j == 10)
	kepler_data[i].Rad = atof(s);
      else if (j == 11)
	kepler_data[i].solRad = atof(s);
      else if (j == 12)
	kepler_data[i].SNR = atof(s);
      else if (j == 13)
	kepler_data[i].log_g = atof(s);
      nread = j + 1;
    }
    if (nread != COLUMNS) break;
  }

  fprintf (stderr, "%d\n", ndata);
  fprintf (stderr, "Complete.\n");
  fclose (fin);
  return ndata;
}
