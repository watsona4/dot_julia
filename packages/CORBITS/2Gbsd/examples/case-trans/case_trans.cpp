#include <transit.h>
#include <koi_input.h>
#include <cstdio>
#include <cstdlib>

kepler_input koi[NDATA];

double trans[3] = {0, 0, 0};
double close[3] = {0, 0, 0};
double freq[3] = {0, 0, 0};

int total = 0;

double Rayleigh_CDF(double x, double sigma) {
  return 1 - exp(-pow(x, 2) / pow(sigma, 2) / 2);
}

double Rayleigh_PDF(double x, double sigma) {
  return x / pow(sigma, 2) * exp(-pow(x, 2) / pow(sigma, 2) / 2);
}

int main() {
  int num = input_data("../../data/koi-data-edit.txt", koi);
  input_orbit io[2];
  FILE *fout = fopen("../../data/trans.csv", "w");
  fprintf(fout, "Per1,Per2,Trans12,Trans23\n");
  for (int j = 1; j < num; j++) {
    for (int k = j - 1; k >= 0 && koi[j].KIC == koi[k].KIC; k--) {
      total++;
      double this_trans[3];
      for (int i = 0; i < 2; i++) {
	io[i].r = 0;
	io[i].e = 0;
	io[i].P = NAN;
	io[i].Omega = 0;
	io[i].omega = 0;
	io[i].use = 1;
      }
      io[0].r_star = koi[j].solRad;
      io[0].i = 0;
      io[0].a = koi[j].a / SR_TO_AU;
      io[1].r_star = koi[k].solRad;
      io[1].a = koi[k].a / SR_TO_AU;
      int last_case = 0;
      for (double phi = 0; phi <= 90 + EPS; phi += .1) {
	io[1].i = DEG_TO_RAD * phi;
	sci_value sv = prob_of_transits_input_orbit(2, io);
	int region_case = (chi_planets(1/io[0].a, 1/io[1].a, DEG_TO_RAD * phi) <= 1) +
	  (chi_planets(1/io[0].a, -1/io[1].a, DEG_TO_RAD * phi) <= 1);
	if (region_case != last_case) {
	  trans[region_case] += phi - .05;
	  this_trans[region_case] = phi - .05;
	  last_case = region_case;
	}
	/* printf ("%.6f\t%.6f\t%4.1f\t%.6f\t%.6f\t%1d\n",
		io[0].r_star / io[0].a, io[1].r_star / io[1].a, phi,
		sv.val, 1 / (io[0].a * io[1].a * sin(DEG_TO_RAD * phi)), region_case);
		if (last_case == 2) break; */
	if (phi <= 10 + EPS) {
	  double approx = 1 / (io[0].a * io[1].a * sin(DEG_TO_RAD * phi));
	  if (last_case == 0) continue;
	  freq[last_case] += 1; // Rayleigh_PDF(phi, 2);
	  if (2 * approx >= sv.val && sv.val * 2 >= approx) {
	    close[last_case] += 1; //Rayleigh_PDF(phi, 2);
	  }
	}
      }
      fprintf (fout, "%.6f,%.6f,%.6f,%.6f\n",koi[j].Per, koi[k].Per,
	       this_trans[1], this_trans[2]);
    }
  }
  printf ("CASE TRANSITIONS: %d %.6f %.6f\n", total, trans[1]/total, trans[2]/total);
  printf ("AT: %.3f %.3f\n", Rayleigh_CDF(trans[1]/total, 2),
	  Rayleigh_CDF(trans[2]/total, 2));
  printf ("ACCURACY: %.3f %.3f\n", close[1]/freq[1], close[2]/freq[2]);
  return 0;
}
