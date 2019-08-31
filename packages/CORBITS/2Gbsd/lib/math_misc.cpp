#include "math_misc.h"

/* --- FUNCTION IMPLEMENTATIONS --- */

double abs_double(double x)
{
    if (x > 0)
    {
        return x;
    }
    return -x;
}

int equal(double a, double b)
{
    if (a < b + EPS && b < a + EPS)
    {
        return 1;
    }
    return 0;
}

double min(double a, double b)
{
    if(a > b)
    {
        return b;
    }
    return a;
}

double radius(double M_star, double P) 
{
       return pow((P / DAYS_IN_YEAR) * (P  / DAYS_IN_YEAR) * M_star, 1.0 / 3.0);
}

double mass_from_radius (double R_star)
{
    if (R_star >= 1)
    {
        return pow (R_star, .8);
    }
    else
    {
        return pow (R_star, .57);
    }
}

double rand_uniform (double range)
{
    return range * rand() / (int) RAND_MAX;
}

double rand_Rayleigh (double sigma)
{
    // inverse CDF based on http://en.wikipedia.org/wiki/Rayleigh_distribution
    return sqrt (- log (1 - rand_uniform (1)) * 2 * sigma * sigma);
}
