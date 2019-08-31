#include "period_dist.h"
#include "koi_input.h"
#include "stat_dist.h"
#include "transit.h"
#include <cstdio>
#include <cstring>
#include <cmath>
#include <cstdlib>
#include <vector>
#include <algorithm>
#define BINWIDTH  30
#define BINNUM    300
#define SNR_CUT   16
#define B_CUT     .80
#define RES_WIDTH 12
#define MMI 0
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
double const nr = false; // resonance analysis?
kepler_input kepler_data[NDATA];
int ndata; // number of KOIs

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
    if (kepler_data[i].KIC == 11442793) return false; // KOI-351
    if (kepler_data[i].KIC == 6021275)  return false; // KOI-284
    if (kepler_data[i].KIC == 11030475) return false; // KOI-2248
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
bool multiplanet(int i)
{
    if (i > 0 && kepler_data[i].KIC == kepler_data[i - 1].KIC) return true;
    if (i + 1 < ndata &&  kepler_data[i].KIC == kepler_data[i + 1].KIC) return true;
    return false;
}

// false if too close to a resonance.
bool check_ratio (double r)
{
    for (int i = 0; i < (int) resonance.size(); i++)
    {
	if (abs (r / resonance[i] - 1) <= r_margin) return false;
    }
    return true;
}

// returns list of nearby resonances
vector <double> nearby_resonances (double r)
{
    vector <double> neighbors;
    for (int i = 0; i < (int) resonance.size(); i++)
    {
	if (abs (r / resonance[i] - 1) <= r_margin)
        {
	    neighbors.push_back(resonance[i]);
        }
    }
    return neighbors;
} 

// computes the probability assuming a rayleigh distribution
double prob_with_rayleigh (double h1, double h2)
{
    // debug
    // bool test = rand() % 100 == 4;
    // if (test) printf("%f %f\n", h1, h2);
    
    double total_prob = 0;
    for (int i = 0; i < TRIALS; i++)
    {
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
void place_bin(int i, int j)
{
    // increase number of systems by one
    N++;
    
    double p1 = kepler_data[i].Per;
    double p2 = kepler_data[j].Per;
    
    // period ratio
    pdf this_prob;
    double r = max (p2 / p1, p1 / p2);
    this_prob.x = log (r); // log-adjusted for rayleigh distribution
    // base-e from http://www.cplusplus.com/reference/cmath/

    // verify not too close to a resonance
    // if (nr && !check_ratio (r)) return; 
    
    // pass to CORBITS if analysis == 2
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
    if (!nr || check_ratio (r))
    {
	PDF.push_back(this_prob);
	// get / verify bin
	int conv = (int) (BINWIDTH * r);
	if (conv >= BINNUM) return; // too large    
	bin[conv] += 1 / prob;
    }
    else
    {
	// smooth over resonance(s)
	vector <double> nearby = nearby_resonances (r);
	for (int i = 0; i < (int) nearby.size(); i++)
        {
	    double res = nearby[i];
	    for (int j = -RES_WIDTH; j <= RES_WIDTH; j++)
            {
		pdf next_prob;
		next_prob.x = log (res * (1 + r_margin * j / RES_WIDTH));
		next_prob.P = 1.0 / prob / (2 * RES_WIDTH + 1) / nearby.size();
		PDF.push_back(next_prob);
		// get / verify bin
		int conv = (int) (BINWIDTH * exp(next_prob.x));
		if (conv >= BINNUM) return; // too large    
		bin[conv] += next_prob.P;
            }
        }
    }
    total += 1 / prob;
    /* if (r < 1.2) {
	fprintf(stderr, "%f %f %f %f %d\n", r, 1 / prob, kepler_data[i].KOI, kepler_data[j].KOI, kepler_data[i].KIC);
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
    for (int i = 0; i < (int) PDF.size(); i++)
    {
	curF += PDF[i].P;
	cdf c;
	c.x = PDF[i].x;
	c.F = curF / total;
	CDF.push_back(c);
    }
}

void set_up()
{
    // clear bins
    for (int i = 0; i < BINNUM; i++)
    {
	bin[i] = 0;
    }
    
    // set up resonances
    for (int i = 7; i <= 1000; i ++)
    {
	if (i % 6 != 1 && i % 6 != 5) resonance.push_back(i / 6.0);
    }
    
    // make histogram
    for (int i = 0; i < ndata; i++)
    {
	for (int j = i + 1; j < ndata; j++)
        {
	    if (!ok(i, j)) continue;
	    if (same_system(i, j))
            {
		place_bin(i, j);         
            }
        }
    }
}

void print_results()
{
    FILE *fout_dist, *fout_hist, *fout_cdf, *fout_py, *fout_R;
    if (analysis == 0) {
	fout_dist = fopen(nr?"../../data/per_all_dist_nr.txt":
			  "../../data/per_all_dist.txt", "w");
	fout_hist = fopen(nr?"../../data/per_all_hist_nr.txt":
			  "../../data/per_all_hist.txt", "w");
	fout_cdf  = fopen(nr?"../../data/per_all_CDF_nr.txt":
			  "../../data/per_all_CDF.txt", "w");
	fout_py   = fopen("../../data/per_all_hist_py.txt", "w");
	fout_R    = fopen("../../data/per_all_hist_r.txt", "w");
    }
    else if (analysis == 1) {
        fout_dist = fopen(nr?"../../data/per_snr_dist_nr.txt":
			  "../../data/per_snr_dist.txt", "w");
	fout_hist = fopen(nr?"../../data/per_snr_hist_nr.txt":
			  "../../data/per_snr_hist.txt", "w");
	fout_cdf  = fopen(nr?"../../data/per_snr_CDF_nr.txt":
			  "../../data/per_snr_CDF.txt", "w");
	fout_py   = fopen("../../data/per_snr_hist_py.txt", "w");
	fout_R    = fopen("../../data/per_snr_hist_r.txt", "w");
    }
    else {
        fout_dist = fopen(nr?"../../data/per_adj_dist_nr.txt":
			  "../../data/per_adj_dist.txt", "w");
	fout_hist = fopen(nr?"../../data/per_adj_hist_nr.txt":
			  "../../data/per_adj_hist.txt", "w");
	fout_cdf  = fopen(nr?"../../data/per_adj_CDF_nr.txt":
			  "../../data/per_adj_CDF.txt", "w");
	fout_py   = fopen("../../data/per_adj_hist_py.txt", "w");
	fout_R    = fopen("../../data/per_adj_hist_r.txt", "w");
    }
    // PDF of period distribution
    for (int i = 0; i < (int) PDF.size(); i++)
    {
	fprintf(fout_dist, "%.5f\n", PDF[i].x); 
    }

    // histogram bins of period distribution
    for (int i = BINWIDTH; i < BINNUM; i++)
    {
	fprintf(fout_hist, "%5.2f\t%.6f\n", 1.0 * i / BINWIDTH, bin[i] / total);
    }

    // to be read in python
    for (int i = 0; i < (int) PDF.size(); i++)
    {
	if (i != 0) fprintf (fout_py, " ");
	fprintf (fout_py, "%.2f", exp(PDF[i].x));
    }
    fprintf (fout_py, "\n");
    for (int i = 0; i < (int) PDF.size(); i++)
    {
	if (i != 0) fprintf (fout_py, " ");
	fprintf (fout_py, "%.6f", PDF[i].P / total);
    }
    fprintf (fout_py, "\n");
  
    // CDF of period distribution
    fprintf(fout_cdf, "%d\n", N);
    for (int i = 0; i < (int) CDF.size(); i++)
    {
	fprintf(fout_cdf, "%.7f\t%.7f\n", CDF[i].x, CDF[i].F);
    }

    fprintf (stderr, "Number of pairs of KOIs: %d\n", PDF.size());
  
    // Output for use in R
    for (int i = 0; i < (int) PDF.size(); i++) {
      fprintf (fout_R, "%15.10f %.10f\n", exp (PDF[i].x), PDF[i].P);
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
