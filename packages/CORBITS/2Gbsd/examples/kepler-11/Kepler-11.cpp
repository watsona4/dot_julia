/* Calculates the conditional probability that exactly six planets of Kepler-11
    are observed given that a hypothetical planet of period 74.34319 days exists    
    Analysis is that of the golden curve of Figure 4 of Lissauer, et al.
    (Nature, 2011)
*/

#include "transit.h"
#include <cstdio>
#include <cstring>
#include <cstdlib>
#define NTRIALS 10000

// Radius and Mass of Kepler-11 from kepler.nasa.gov
double R11 = 1.10;
double M11 = 0.95;

int n_planets;
double P11[10];
int use[10];
input_orbit IO11[10];
orbit O11[10];
planet_ellipse planets11[10];

void read_input()
{
    FILE *fin = fopen("Kepler-11.in", "r");
    fscanf (fin, "%d", &n_planets);
    // fprintf (stderr, "%d\n", n_planets);
    for (int i = 0; i < n_planets; i++)
    {
        char s[100];
        fscanf (fin, "%s %d", s, &use[i]);
        P11[i] = atof (s);
        IO11[i].a      = radius (M11, P11[i]);
        // fprintf (stderr, "%d %f\n", i + 1, IO11[i].a);
        IO11[i].r_star = R11 * SR_TO_AU;
        IO11[i].r      = 0;
        IO11[i].e      = 0;
        IO11[i].omega  = 0;
    }
    fclose (fin);
}

double prob(double sigma_i)
{
    double sum = 0;
    for (int i = 0; i < NTRIALS; i++)
    {
        for (int k = 0; k < n_planets; k++)
        {
            for (int j = 0; j < n_planets; j++)
            {
                IO11[j].i     = rand_Rayleigh (sigma_i) / RAD_TO_DEG;
                IO11[j].Omega = rand_uniform  (2 * PI); 
                O11[j]        = input_orbit_to_orbit (IO11[j]);
                O11[j].use    = (int) (k != j);
                planets11[j]  = convert (O11[j]);
            }
            // as e = 0 for all planets, values are EXACT
            sum += prob_of_transits_approx (n_planets, planets11);
        }
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
