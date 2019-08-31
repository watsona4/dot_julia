#include <transit.h>
#include <koi_input.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <vector>
#include <algorithm>
#define NTRIALS 1000
#define MAX_PLANETS 20
#define N_INCLINATIONS 4

kepler_input koi[NDATA];
int ndata;

double prob(int n_planets, input_orbit* io, double sigma_i) {
  double sum = 0;
  orbit o[MAX_PLANETS];
  planet_ellipse pe[MAX_PLANETS];
  for (int i = 0; i < NTRIALS; i++) {
    for (int j = 0; j < n_planets; j++) {
      io[j].i     = rand_Rayleigh (sigma_i) / RAD_TO_DEG;
      io[j].Omega = rand_uniform  (2 * PI); 
      o[j]        = input_orbit_to_orbit (io[j]);
      o[j].use    = 1;
      pe[j]  = convert (o[j]);
    }
    // as e = 0 for all planets, values are EXACT
    sum += prob_of_transits_approx (n_planets, pe);
  }
  return sum / NTRIALS;
}

void print_table() {
  // OPEN OUTPUT FILE
  FILE *fout = fopen ("../../data/koi.tex", "w");
  if (fout == NULL) exit (1);

  double angle[N_INCLINATIONS] = {0, 1, 2, 10};
  
  // HEADER
  fprintf (fout, "\\begin{longtable}{lllllll}\n");
  fprintf (fout, "KOI & N & Per");
  for (int i = 0; i < N_INCLINATIONS; i++) {
    fprintf (fout, " & i = $%.f^{\\circ}$", angle[i]);
  }
  fprintf (fout, "\\\\\\hline\n");
  
  // PROCESS DATA
  for (int i = 0; i < ndata; i++) {
    
    input_orbit io[MAX_PLANETS];
    std::vector <double> period_list;
    
    period_list.push_back (koi[i].Per);
    int j = i;
    while (j != ndata - 1 && koi[i].KIC == koi[j + 1].KIC) {
      j++;   
      period_list.push_back (koi[j].Per);
    }
    int n_planets = period_list.size();
    // filter systems with <= 2 planets
    if (n_planets <= 2 && koi[i].KIC != 3) continue;
    std::sort (period_list.begin(), period_list.end());
    // fprintf (stderr, "KOI-%.f\n", koi[i].KOI);

    // PRINT ROW
    fprintf (fout, "KOI-%.f & %d & ", koi[i].KOI, n_planets);
    for (int k = 0; k < n_planets; k++) {
      double R = koi[k + i].solRad * SR_TO_KM * 1000;
      double g = pow (10, koi[k + i].log_g) / 100; // (m / sec^2)
      double M = R * R * g / G / SOLAR_MASS;
      // fprintf (stderr, "SM: %e %e %e\n", R, g, M);
      io[k].a      = radius (M, period_list[k]);
      io[k].r_star = koi[k].solRad * SR_TO_AU;
      // fprintf (stderr, "%e\n", io[k].r_star / io[k].a);
      io[k].r      = 0;
      io[k].e      = 0;
      io[k].omega  = 0;
    } 
    for (int k = 0; k < (int) period_list.size(); k++) {
      fprintf (fout, "%.2f", period_list[k]);
      if (k != (int) period_list.size() - 1) fprintf (fout, ", ");
    }
    for (int k = 0; k < N_INCLINATIONS; k++) {
      double curp = prob (n_planets, io, sqrt (2 / PI) * angle[k]);
      // fprintf (stderr, "%e\n", curp);
      fprintf (fout, " & %.3f", curp);
    }
    fprintf (fout, "\\\\\n");
    fflush (fout);
    i = j;
  }

  // SPECIAL ROWS
  fprintf (fout, "Inner Planets & 4 & 87.97, 224.70, 365.26, 686.97 & 3.740e-003 & 2.029e-004 & 2.541e-005 & 2.211e-007\\\\\n");
  fprintf (fout, "Outer Planets & 4 & 4332.59, 10759.22, 30799.10, 60190.03 & 1.945e-004 & 4.366e-009 & 9.341e-010 & 0.000e+000\\\\\n");
  fprintf (fout, "Venus, Earth & 2 & 224.70, 365.26 & 6.848e-003 & 2.766e-003 & 1.478e-003 & 2.725e-004\\\\\n");

  // CAPTION
  fprintf (fout, "\\caption{ }\n");

  // LABEL
  fprintf (fout, "\\label{tbl:koi}\n");

  // CLOSING
  fprintf (fout, "\\end{longtable}\n");
  fclose (fout);
}

int main() {
  ndata = input_data("../../data/koi-data-edit.txt", koi);
  print_table();
}
