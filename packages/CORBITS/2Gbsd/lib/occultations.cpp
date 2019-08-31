#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "occultations.h"

/* --- FUNCTION IMPLEMENTATIONS --- */

/* implementations of eccentric_anomaly, location, radius_orbit, and
   true_anomaly are based on:
   http://en.wikipedia.org/wiki/True_anomaly
   http://en.wikipedia.org/wiki/Eccentric_anomaly
   http://en.wikipedia.org/wiki/Mean_anomaly
   Murrary and Correia, "Keplerian Orbits and Dynamics of Exoplanets":
     Seager, Exoplanets
*/

double eccentric_anomaly(double M, double e) {
  // Use Newton-Raphson Method
  double const NUM = 10; // number of iterations
  double E = M;
  int i;
  for (i = 0; i < NUM; i++)
    {
      double err = E - e * sin(E) - M;
      double dir = 1 - e * cos(E);
      if (equal(err, 0)) break; // cut-off for efficiency
      E -= err/dir;
    }
  return E;
}

double true_anomaly(double E, double e) {
  if (equal(e, 0)) return E;
  return 2 * atan2(sqrt(1 + e) * sin(E / 2), sqrt(1 - e) * cos(E / 2));
}

double radius_orbit(double f, double a, double e) {
  return a * (1 - e * e) / (1 + e * cos(f));
}

point3D location(orbit O, double M) {
  double E = eccentric_anomaly(M, O.e);
  double f = true_anomaly(E, O.e);
  double cos_f = cos(f);
  double sin_f = sin(f);
  double r = radius_orbit(f, O.a, O.e);
    
  point3D u = normalize(O.periapse);
  point3D v = normalize(cross_product(O.periapse, O.pole));
  point3D p;
    
  p.x = (u.x * cos_f + v.x * sin_f) * r;
  p.y = (u.y * cos_f + v.y * sin_f) * r;
  p.z = (u.z * cos_f + v.z * sin_f) * r;
    
  return p;
}

double ODT_ellipse(orbit O1, orbit O2, double r_star) {
  int TOTAL = 1440;
  double prob = 0;
  point3D p1[TOTAL], p2[TOTAL];
  int i, j;
    
  for (i = 0; i < TOTAL; i++) {
    p1[i] = location(O1, 2 * PI * i / TOTAL);
    p2[i] = location(O2, 2 * PI * i / TOTAL);
  }
    
  for (i = 0; i <= TOTAL / 2; i++) {
    for (j = 0; j < TOTAL; j++) {
      double p = ODT_prob(p1[i], O1.r, p2[j], O2.r, r_star);
      prob += p;
      if (i == 0 || i == TOTAL / 2) {
	prob -= p / 2;
      }
    }
  }
  return prob / (TOTAL * TOTAL / 2);
}

double ODT_prob(point3D p1, double r1, point3D p2, double r2, double r_star) {
  int i, j;
  planet_ellipse p[3];
  double a1 = dot_product(p1, p1);
  double a2 = dot_product(p2, p2);
  p[0].pole[0] = p1;
  p[0].pole[1] = -p1;
  p[1].pole[0] = p2;
  p[1].pole[1] = -p2;
    
  double dp = dot_product(p1, p2);
  if (dp < 0) return 0;
  double f1, f2;
  if (a1 > a2) {
    f1 = (r_star - r1 - r2) * (r_star - r1 - r2) / a1;
    f2 = (r_star * r_star) / a2;
  }
  else {
    f1 = (r_star * r_star) / a1;
    f2 = (r_star - r1 - r2) * (r_star - r1 - r2) / a2;
  }
  double threshold = (1 - f1) * (1 - f2) + f1 * f2 +
    2 * sqrt((1 - f1) * (1 - f2) * f1 * f2);
  if (dp * dp / (a1 * a2) + 1e-7 < threshold) return 0;
         
  p[0].use = 0;
  p[0].h = sqrt(1 - r_star * r_star / a1);
  p[1].use = 0;
  p[1].h = sqrt(1 - r_star * r_star / a2);
            
  double dist_sq = distance_squared(p1, p2);

  p[2].pole[0] = point3D(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
  p[2].pole[1] = -p[2].pole[0];

  p[2].use = 0;
  p[2].h = sqrt(1 - (r1 + r2) * (r1 + r2) / dist_sq);

  for (i = 0; i < 3; i++) {
    for (int j = 0; j < 2; j++) {
      p[i].pole[j] = normalize(p[i].pole[j]);
    }
  }
    
  double prob = prob_of_transits_approx(3, p);

  for (i = 0; i < 3; i++) {
    for (j = i + 1; j < 3; j++) {
      if ((equal(p[i].pole[0].x,p[j].pole[0].x) &&
	   equal(p[i].pole[0].y,p[j].pole[0].y) &&
	   equal(p[i].pole[0].z,p[j].pole[0].z) &&
	   equal(p[i].h,p[j].h)) ||
	  (equal(p[i].pole[0].x,-p[j].pole[0].x) &&
	   equal(p[i].pole[0].y,-p[j].pole[0].y) &&
	   equal(p[i].pole[0].z,-p[j].pole[0].z) &&
	   equal(p[i].h,p[j].h))) {
	planet_ellipse p_new;
	p_new = p[i];
	p[i] = p[2];
	p[2] = p_new;
	prob = prob_of_transits_approx(2, p);
      }
    }
  }
    
  if (!(prob <= 1e-7 + min(min(1 - p[0].h, 1 - p[1].h), 1 - p[2].h))) {
    prob = 0;
  }
  return prob / 2;
}

double PPO_ellipse(orbit O1, orbit O2)
{
  int TOTAL = 360;
  double prob = 0;
  point3D p1[TOTAL], p2[TOTAL];
  int i, j;
    
  for (i = 0; i < TOTAL; i++) {
    p1[i] = location(O1, 2 * PI * i / TOTAL);
    p2[i] = location(O2, 2 * PI * i / TOTAL);
  }
    
  for (i = 0; i < TOTAL / 2; i++) {
    for (j = 0; j < TOTAL; j++) {
      double dist_sq = distance_squared(p1[i], p2[j]);
      if (dist_sq < (O1.r + O2.r) * (O1.r + O2.r)) {
	prob += 1;
      } else {
	prob += 1 - sqrt(1 - (O1.r + O2.r) * (O1.r + O2.r) / dist_sq);
      }
    }
  }
  return prob / (TOTAL * TOTAL / 2);
}
