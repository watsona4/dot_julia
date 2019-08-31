#include "math_misc.h"

/* --- STRUCTS --- */

/* 3D point data type */
struct point3D {
    double x;
    double y;
    double z;
    point3D() {
      x = 0;
      y = 0;
      z = 0;
    }
    point3D(double _x, double _y, double _z) {
      x = _x;
      y = _y;
      z = _z;
    }
};

/* --- OPERATORS --- */
point3D operator-(point3D p);

/* --- FUNCTION PROTOTYPES --- */

/* dot product of two point3Ds */
/* From http://en.wikipedia.org/wiki/Cross_product */
point3D cross_product(point3D a, point3D b);

/* dot product of two point3Ds */
double dot_product(point3D a, point3D b);

/* the square of the distance between two point3Ds */
double distance_squared(point3D a, point3D b);

/* makes a new point3D */
point3D new_point3D(double x, double y, double z);

/* returns a unit point3D perpendicular to two given point3Ds*/
point3D normal_point3D(point3D pole, point3D p);

/* returns a unit point3D in the same direction */
point3D normalize(point3D v);

/* returns a point3D orthogonal to point3D pole */
point3D orthogonal_vector(point3D pole);

/* Returns the radian angle between two point3Ds in the range [-pi, pi] */
double point3D_angle(point3D a, point3D b);

/* debugging function */
void print_point3D(point3D p);

/* projection of a into plane of pole, assume pole is a unit */
point3D projection(point3D a, point3D pole);

/* normalized projection of w into span(u, v) */
point3D projection_span(point3D u, point3D v, point3D w);

/* constructs a random point on the surface of a unit sphere. */
/* Algorithm based on <http://en.wikipedia.org/wiki/N-sphere> */
point3D random_point_sphere();

/* the angle v makes with orthogonal_vector(pole) when v is projected
   into the plane normal to pole */
double relative_angle(point3D pole, point3D v);

/* rotate phi RADIANS about the x axis */
/* Based on Murray and Correia (2010) equations (49-52) */
/* http://en.wikipedia.org/wiki/Rotation_matrix */
point3D rotate_x(point3D p, double phi);

/* rotate phi RADIANS about the y axis */
/* Based on Murray and Correia (2010) equations (49-52) */
/* http://en.wikipedia.org/wiki/Rotation_matrix */
point3D rotate_y(point3D p, double phi);

/* rotate phi RADIANS about the z axis */
/* Based on Murray and Correia (2010) equations (49-52) */
/* http://en.wikipedia.org/wiki/Rotation_matrix */
point3D rotate_z(point3D p, double phi);
