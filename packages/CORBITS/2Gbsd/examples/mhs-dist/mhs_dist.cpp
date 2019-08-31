// #include "mhs_dist.h"
#include "koi_input.h"
#include "stat_dist.h"
#include "transit.h"
#include <cstdio>
#include <cstring>
#include <vector>
#include <cmath>
#include <vector>
#include <algorithm>
#define BINWIDTH  1
#define BINNUM    100
#define SNR_CUT   16
#define B_CUT     .80
#define RES_WIDTH 12
#define MMI 5
#define TRIALS 10000

using namespace std;

int analysis; // kind of analysis to be done
// 0: all data (except outliers)
// 1: data passing SNR and impact parameter cuts
// 2: same as 1, but adjusted for geometric bias
double bin[BINNUM];
vector <cdf> CDF;
vector <pdf> PDF;
vector <double> resonance;
double total = 0;
double const r_margin = .10;
int N = 0; // number of data points;
// run once with nr = false, then again with nr = true
double const nr = false;
kepler_input kepler_data[NDATA];
int ndata;

// Clears the memory of all global variables modified while computing PDF / CDF
void release() {
  memset (bin, 0, sizeof (bin));
  CDF.clear();
  PDF.clear();
  resonance.clear();
  total = 0;
}

// checks that i is not part of KOI 284, 2248, or 351
bool outlier_check (int i)
{
  if (kepler_data[i].KIC == 11442793) return false; // 351
  if (kepler_data[i].KIC == 6021275)  return false; // 284
  if (kepler_data[i].KIC == 11030475) return false; // 2248
  return true;    
}

// checks if the pair of planets meet the SNR and impact parameter thresholds
// also checks that neither of the planets are from a "bad" system
bool ok(int i, int j)
{
  if (!outlier_check (i) || !outlier_check (j)) return false;
  if (analysis == 0) return true;
  bool b1 = kepler_data[i].SNR >= SNR_CUT && kepler_data[i].b <= B_CUT;
  bool b2 = kepler_data[j].SNR >= SNR_CUT && kepler_data[j].b <= B_CUT;
  double r = pow (kepler_data[i].Per / kepler_data[j].Per, -1.0 / 3);
  return b1 && b2 && kepler_data[i].SNR / r>= SNR_CUT && kepler_data[j].SNR  * r >= SNR_CUT;
}

bool same_system(int i, int j)
{
  return kepler_data[i].KIC == kepler_data[j].KIC;
}

// checks if the planet is in a multiplanetary system
bool multiplanet(int i) {
  if (i > 0 && kepler_data[i].KIC == kepler_data[i - 1].KIC) return true;
  if (i + 1 < ndata &&  kepler_data[i].KIC == kepler_data[i + 1].KIC) return true;
  return false;
}

double delta (int i, int j) {
  // based on Darin's Origins grant proposal, Hansen & Murray, etc.
  double a1 = kepler_data[i].a;
  double a2 = kepler_data[j].a;
  if (a1 < a2) {
    swap (a1, a2);
  }
  double r1 = kepler_data[i].Rad;
  double r2 = kepler_data[j].Rad;
  double m1 = pow (r1, 2.06);
  double m2 = pow (r2, 2.06);
  // fprintf (stderr, "radii: %f %f\n", r1, r2);
  double M_star = kepler_data[i].solRad * SM_to_EM;
  return (a1 - a2) / ((a1 + a2) / 2) * pow ((m1 + m2) / (3 * M_star), -1.0 / 3);
}

// computes the probability assuming a rayleigh distribution
double prob_with_rayleigh (double h1, double h2) {
  // debug
  // bool test = rand() % 100 == 4;
  // if (test) printf("%f %f\n", h1, h2);
    
  double total_prob = 0;
  for (int i = 0; i < TRIALS; i++) {
    double theta = rand_Rayleigh (MMI * sqrt (2 / PI)) / RAD_TO_DEG;
        
    // set up
    planet_ellipse p[2];
    p[0].h = h1;
    p[0].use = 1;
    p[0].pole[0] = new_point3D (1, 0, 0);
    p[0].pole[1] = new_point3D (-1, 0, 0);
        
    p[1].h = h2;
    p[1].use = 1; 
    p[1].pole[0] = new_point3D (cos (theta), sin (theta), 0);
    p[1].pole[1] = new_point3D (-cos (theta), -sin (theta), 0);
        
    // get prob
    total_prob += prob_of_transits_approx (2, p);
  }
  return total_prob / TRIALS;
}

// places the pair of planets in some bin
void place_bin(int i, int j) {
  // increase number of systems by one
  N++;
    
  // compute delta
  pdf this_prob;
  double r = delta (i, j);
  this_prob.x = r;
        
  // pass to CORBITS if analysis = 2
  double prob;
  if (analysis == 2) {
    double h1 =  B_CUT * kepler_data[i].solRad / kepler_data[i].a * SR_TO_AU;
    double h2 =  B_CUT * kepler_data[j].solRad / kepler_data[j].a * SR_TO_AU;
    prob = prob_with_rayleigh (h1, h2);
  }
  else {
    prob = 1;
  }
  this_prob.P = 1 / prob;
    
  // update PDF
  PDF.push_back(this_prob);
    
  // get / verify bin
  int conv = (int) (BINWIDTH * r);
  if (conv >= BINNUM) return; // too large    
  bin[conv] += 1 / prob;
  total += 1 / prob;
  // fprintf(stderr, "%f %f %f\n", r, 1 / prob , kepler_data[i].KOI);
  // fprintf (stderr, "%d %d\n", nan[0], nan[1]);
  /* if () {
    fprintf (stderr, "FAIL: %d %f\n", i, kepler_data[i].KOI);
    } */
}

void make_cdf()
{
  // sort the pdf
  sort (PDF.begin(), PDF.end(), pdf_cmp);
  double curF = 0;
  cdf c;
  c.x = 0;
  c.F = 0;
  CDF.push_back(c);
  for (int i = 0; i < (int) PDF.size(); i++) {
    curF += PDF[i].P;
    cdf c;
    c.x = PDF[i].x;
    c.F = curF / total;
    CDF.push_back(c);
  }
}

void set_up() {
  // clear bins
  for (int i = 0; i < BINNUM; i++) {
    bin[i] = 0;
  }
    
  // make histogram
  for (int i = 0; i < ndata; i++) {
    for (int j = i + 1; j < ndata; j++) {
      if (!ok(i, j)) continue;
      if (same_system(i, j) && j == i + 1) {
	place_bin(i, j);         
      }
    }
  }
}

void print_results()
{
  FILE *fout_dist, *fout_hist, *fout_cdf, *fout_py, *fout_R;
  if (analysis == 0) {
    fout_dist = fopen(nr?"../../data/mhs_all_dist_nr.txt":
		      "../../data/mhs_all_dist.txt", "w");
    fout_hist = fopen(nr?"../../data/mhs_all_hist_nr.txt":
		      "../../data/mhs_all_hist.txt", "w");
    fout_cdf  = fopen(nr?"../../data/mhs_all_CDF_nr.txt":
		      "../../data/mhs_all_CDF.txt", "w");
    fout_py   = fopen("../../data/mhs_all_hist_py.txt", "w");
    fout_R    = fopen("../../data/mhs_all_hist_r.txt", "w");
  }
  else if (analysis == 1) {
    fout_dist = fopen(nr?"../../data/mhs_snr_dist_nr.txt":
		      "../../data/mhs_snr_dist.txt", "w");
    fout_hist = fopen(nr?"../../data/mhs_snr_hist_nr.txt":
		      "../../data/mhs_snr_hist.txt", "w");
    fout_cdf  = fopen(nr?"../../data/mhs_snr_CDF_nr.txt":
		      "../../data/mhs_snr_CDF.txt", "w");
    fout_py   = fopen("../../data/mhs_snr_hist_py.txt", "w");
    fout_R    = fopen("../../data/mhs_snr_hist_r.txt", "w");
  }
  else {
    fout_dist = fopen(nr?"../../data/mhs_adj_dist_nr.txt":
		      "../../data/mhs_adj_dist.txt", "w");
    fout_hist = fopen(nr?"../../data/mhs_adj_hist_nr.txt":
		      "../../data/mhs_adj_hist.txt", "w");
    fout_cdf  = fopen(nr?"../../data/mhs_adj_CDF_nr.txt":
		      "../../data/mhs_adj_CDF.txt", "w");
    fout_py   = fopen("../../data/mhs_adj_hist_py.txt", "w");
    fout_R    = fopen("../../data/mhs_adj_hist_r.txt", "w");
  }
  // PDF of period distribution
  for (int i = 0; i < (int) PDF.size(); i++) {
    fprintf(fout_dist, "%.5f\n", PDF[i].x); 
  }

  // histogram bins of period distribution
  for (int i = BINWIDTH; i < BINNUM; i++) {
    fprintf(fout_hist, "%5.2f\t%.6f\n", 1.0 * i / BINWIDTH, bin[i] / total);
  }

  // to be read in python
  for (int i = 0; i < (int) PDF.size(); i++) {
    if (i != 0) fprintf (fout_py, " ");
    fprintf (fout_py, "%.2f", PDF[i].x);
  }
  fprintf (fout_py, "\n");
  for (int i = 0; i < (int) PDF.size(); i++) {
    if (i != 0) fprintf (fout_py, " ");
    fprintf (fout_py, "%.6f", PDF[i].P / total);
  }
  fprintf (fout_py, "\n");
  
  // CDF of period distribution
  fprintf(fout_cdf, "%d\n", N);
  for (int i = 0; i < (int) CDF.size(); i++) {
    fprintf(fout_cdf, "%.7f\t%.7f\n", CDF[i].x, CDF[i].F);
  }

  fprintf (stderr, "Number of pairs of KOIs: %d\n", PDF.size());
  
  // Output for use in R
  for (int i = 0; i < (int) PDF.size(); i++) {
    fprintf (fout_R, "%15.10f %.10f\n", PDF[i].x, PDF[i].P);
  }
}

int main()
{
  // Read KOI data from file
  ndata = input_data("../../data/koi-data-edit.txt", kepler_data);
  fprintf(stderr, "Read data\n\n");

  for (analysis = 0; analysis <= 2; analysis++) {
    fprintf(stderr, "Start of analysis %d\n", analysis);
    // Initialize histogram and create the CDF
    set_up();
    fprintf(stderr, "PDF made\n");
  
    // Create the CDF
    make_cdf();
    fprintf(stderr, "CDF made\n");

    // Output
    print_results();
    fprintf(stderr, "Output completed for %d\n\n", analysis);
  
    // Release global variables
    release();
  }
}

