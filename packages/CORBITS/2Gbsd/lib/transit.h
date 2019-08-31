#include "point3D.h"

/* --- STRUCTS --- */

/* intersection of two transit boundaries */
typedef struct{
    int num;
    point3D p[8];
} crossing;

/* internal ellipse representation */
typedef struct {
    double a;
    double e;
    double r;
    double r_star;
    int use;
    point3D pole;
    point3D periapse;
} orbit;

/* external orbit representation */
typedef struct {
    double a;
    double r_star;
    double r;
    double e;
    double P;
    double Omega;
    double omega;
    double i;
    int use;
} input_orbit;

/* approximate boundary of ellipse transit region */
/* approximation with two sloped small circles    */
/* inspired from (Winn, 2010), see: Exoplanets, Sara Seager editor*/
typedef struct{
    point3D pole[2]; /* two poles */
    int use;         /* inside or outside? */
    double h;        /* distance from each plane to the origin */
} planet_ellipse;

/* intersection point of two boundary curves */
typedef struct {
    point3D p;
    int pole[2]; /* Memory locations of pole coordinates */
    int index[2]; /* which of the two poles do we take? */
    int adj[2]; /* Adjacent vertices */
} vertex;


/* --- FUNCTION PROTOTYPES --- */

/* returns the characteristic number of the system */
double chi_planets(double h1, double h2, double phi);

/* converts an elliptical orbit into an approximate planet_ellipse data type */
planet_ellipse convert(orbit o);

/* worst-case upper bound */
planet_ellipse convert_upper_bound(orbit o);

/* worst-case lower bound */
planet_ellipse convert_lower_bound(orbit o);

/* is a point3D in the region formed by multiple planets? */
int in_hull(point3D point, int n, planet_ellipse p[]);

/* is a point3D in the exact region formed by orbits? */
int in_hull_exact(point3D point, int n, orbit o[]);

/* is a point3D in the region formed by the same planet? */
int in_transit(point3D point, planet_ellipse p);

/* is point in the region made by orbit o */
/* implementation based on Winn(2010) */
int in_transit_exact(point3D point, orbit o);

/* Converts an input_orbit to an orbit which serves as an approximation */
orbit input_orbit_to_orbit(input_orbit io);

/* intersection of two small circles */
crossing intersection(point3D pole1, double h1, point3D pole2, double h2);

/*Finds all intersections between the two transit regions*/
crossing intersection_all(planet_ellipse a, planet_ellipse b);

/* Converts an orbit to an input_orbit */
input_orbit orbit_to_input_orbit(orbit o);

/* finds the prob of all n observations with an analytic approx algorithm */
double prob_of_transits_approx(const int n, planet_ellipse p[]);

/* finds the probability of all n observations with an approx MC algorithm */
double prob_of_transits_approx_monte_carlo(const int n, planet_ellipse p[], int n_trials);

/* Finds the prob of transit with error bars */
sci_value prob_of_transits_orbit(const int n, orbit o[]);

/* Finds the prob of transit with error bars */
sci_value prob_of_transits_input_orbit(const int n, input_orbit io[]);

/* finds the probability of all n observations with an MC algorithm */
double prob_of_transits_monte_carlo(const int n, orbit o[], int n_trials);

/* reconstructs a point, given a pole */
/* inverse of relative_angle from point3D.c */
point3D point3D_from_angle(planet_ellipse p, double angle, int sign);
