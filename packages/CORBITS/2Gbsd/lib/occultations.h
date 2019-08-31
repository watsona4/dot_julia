/* Functions for investigation exoplanet occultations */

#include "transit.h"

/* --- FUNCTION PROTOTYPES --- */

/* computes the eccentric anomaly from the mean anomaly and the eccentricity */
double eccentric_anomaly(double M, double e);

/* location of planet at mean anomaly M, assumes star is origin */
point3D location(orbit O, double M);

/* compute the probability of observing an ODT from the perspective of a
   random observer when the locations of the two planets are fixed */
double ODT_prob(point3D p1, double r1, point3D p2, double r2, double r_star);

/* distance planet is from star at true anomaly f */
double radius_orbit(double f, double a, double e);

/* computes the true anomaly from the eccentric anomaly */
double true_anomaly(double E, double e);

/* Computes the probability of an overlapping double transit being observed
   by a random observer at a random time */
double ODT_ellipse(orbit O1, orbit O2, double r_star);

/* Compute the probability of a planet-planet occultation being observed
   by a random observer at a random time */
double PPO_ellipse(orbit O1, orbit O2);
