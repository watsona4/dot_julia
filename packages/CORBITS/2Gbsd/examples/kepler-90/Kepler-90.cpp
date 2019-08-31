/* Calculates the conditional probability that exactly six planets of Kepler-90
    are observed 
    Analysis is similar to that of Lissauer, et al. (Nature, 2011)
*/

#include "transit.h"
#include <cstdio>
#include <cstring>
#include <cstdlib>
#define NTRIALS 100000

// Radius and Mass of Kepler-90
double R90 = 1.02;
double M90 = 1.09;

int n_planets;
double P90[10];
int use[10];
input_orbit IO90[10];
orbit O90[10];
planet_ellipse planets90[10];

void read_input()
{
    FILE *fin = fopen("Kepler-90.in", "r");
    fscanf (fin, "%d", &n_planets);
    // fprintf (stderr, "%d\n", n_planets);
    for (int i = 0; i < n_planets; i++)
    {
        char s[100];
        fscanf (fin, "%s %d", s, &use[i]);
        P90[i] = atof (s);
        IO90[i].a      = radius (M90, P90[i]);
        // fprintf (stderr, "%d %f\n", i + 1, IO90[i].a);
        IO90[i].r_star = R90 * SR_TO_AU;
        IO90[i].r      = 0;
        IO90[i].e      = 0;
        IO90[i].omega  = 0;
    }
    fclose (fin);
}

double prob(double sigma_i)
{
    double sum = 0;
    for (int i = 0; i < NTRIALS; i++)
    {
      //        for (int k = 0; k < n_planets; k++)
      //  {
            for (int j = 0; j < n_planets; j++)
            {
                IO90[j].i     = rand_Rayleigh (sigma_i) / RAD_TO_DEG;
                IO90[j].Omega = rand_uniform  (2 * PI); 
                O90[j]        = input_orbit_to_orbit (IO90[j]);
                O90[j].use    = use[j]; // (int) (k != j);
                planets90[j]  = convert (O90[j]);
            }
            // as e = 0 for all planets, values are EXACT
            sum += prob_of_transits_approx (n_planets, planets90);
	    //        }
    }
    return sum / NTRIALS;
}

void print_results ()
{
    for (double i = 0; i <= 6; i += .1)
    {
        double curp = prob(i * sqrt (2 / PI));
        printf ("%3.1f\t%.10lf\n", i, curp);
    }
}

int main()
{
    read_input ();
    print_results ();
}
