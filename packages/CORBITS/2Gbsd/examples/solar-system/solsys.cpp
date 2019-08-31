#include <cstdio>
#include <cstring>
#include <cassert>
#include <ctime>
#include <algorithm>
#include "transit.h"
#define NDATA 8

using namespace std;

typedef struct {
    char name[100];
    double a;
    double r;
    double e;
    double omega;
    double Omega;
    double i;
} input;

input data[NDATA];
// descriptive labels for ternary bits
char label[3][100] = {"exclude", "include", "ignore"};

void read_input(FILE *fin) {
    for(int i = 0; i < NDATA; i++) {
	for(int j = 0; j < 7; j++) {
	    char s[100] = "";
	    int a = fscanf(fin, "%s", s);
	    if (a == EOF) break;
	    if (j == 0)
		for (int k = 0; k <= (int) strlen(s); k++)
		    data[i].name[k] = s[k];
	    else if (j == 1)
		data[i].a = atof(s);
	    else if (j == 2)
		data[i].e = atof(s);
	    else if (j == 3)
		data[i].i = atof(s);
	    else if (j == 4)
		data[i].Omega = atof(s);
	    else if (j == 5) {
		data[i].omega = atof(s);
		data[i].omega -= data[i].Omega;
	    }
	    else if (j == 6)
		data[i].r = atof(s);
	}
    }
}

void simulate(FILE *fout) {
    input_orbit IO[NDATA];
    for (int i = 0; i < NDATA; i++) {
	IO[i].a = data[i].a;
	IO[i].r_star = 1 * SR_TO_AU;
	IO[i].e = data[i].e;
	IO[i].Omega = data[i].Omega / RAD_TO_DEG;
	IO[i].omega = data[i].omega / RAD_TO_DEG;
	IO[i].i = data[i].i / RAD_TO_DEG;
    }
    
    // convert orbital parameters into format useable by CORBITS
    orbit O[NDATA];
    planet_ellipse P[NDATA];
    for (int i = 0; i < NDATA; i++) {
	O[i] = input_orbit_to_orbit(IO[i]);
	fprintf(stderr, "%s %f %f %f\n", data[i].name, O[i].pole.x, O[i].pole.y, O[i].pole.z);
	fprintf(stderr, "  %f %f %f\n", O[i].periapse.x, O[i].periapse.y, O[i].periapse.z);
	
	P[i] = convert (O[i]);
	fprintf (stderr, "%s %f %d\n", data[i].name, P[i].h, P[i].use);
	fprintf (stderr, "%f %f %f\n", P[i].pole[0].x, P[i].pole[0].y, P[i].pole[0].z);
	fprintf (stderr, "%f %f %f\n", P[i].pole[1].x, P[i].pole[1].y, P[i].pole[1].z);
    }
    
    // header
    for (int i = 0; i < NDATA; i++) {
	fprintf (fout, "%s,", data[i].name);
    }
    fprintf (fout, "Probability,PosErr,NegErr\n");

    // body
    for (int i = 0; i < pow(3, NDATA) - 1; i++) {
	int a = i;
	planet_ellipse Q[NDATA];
	input_orbit Q_IO[NDATA];
	int k = 0;
	for (int j = 0; j < NDATA; j++) {
	    P[j].use = a % 3;
	    IO[j].use = a % 3;
	    a /= 3;
	    if(P[j].use != 2) {
		Q_IO[k] = IO[j];
		Q[k++] = P[j];
	    }
	}
	// double prob = prob_of_transits_approx(k, Q);
	sci_value prob2 = prob_of_transits_input_orbit(k, Q_IO);
	for (int j = 0; j < NDATA; j++) {
	    fprintf(fout, "%d,", P[j].use);
	}
	fprintf(fout, "%e,%e,%e\n", prob2.val, prob2.pos_err, prob2.neg_err);
    }
}

int main()
{
    // Source of data
    // http://ssd.jpl.nasa.gov/?planet_phys_par
    // http://ssd.jpl.nasa.gov/?planet_pos
    FILE *fin  = fopen("../../data/solsys.in","r");
    assert (fin != NULL);
    FILE *fout = fopen("../../data/solsys.csv","w");
  
    read_input(fin);
    fclose(fin);
  
    fprintf(stderr, "Running time: %d\n", (int) clock());

    simulate(fout);
    fclose(fout);
    
    fprintf(stderr, "Running time: %d\n", (int) clock());

    return 0;
}
