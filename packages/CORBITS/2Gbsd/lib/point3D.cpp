/* point3D data type with some useful functions */

#include <stdlib.h>
#include <stdio.h>
#include "point3D.h"

/* --- OPERATOR IMPLEMENTATIONS --- */

point3D operator-(point3D p) {
  return point3D(-p.x, -p.y, -p.z);
}

/* --- FUNCTION IMPLEMENTATIONS --- */

point3D cross_product(point3D a, point3D b)
{
  point3D c;
  c.x = a.y * b.z - a.z * b.y;
  c.y = a.z * b.x - a.x * b.z;
  c.z = a.x * b.y - a.y * b.x;
  return c;
}

double dot_product(point3D a, point3D b)
{
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

double distance_squared(point3D a, point3D b) {
  return (a.x - b.x) * (a.x - b.x) +
    (a.y - b.y) * (a.y - b.y) +
    (a.z - b.z) * (a.z - b.z);
}

point3D new_point3D(double x, double y, double z)
{
  point3D a;
  a.x = x;
  a.y = y;
  a.z = z;
  return a;
}

point3D normal_point3D(point3D pole, point3D p)
{
  point3D v = cross_product(p, pole);
  v = normalize(v);
  if (dot_product(pole, p) < 0) {
    v.x = -v.x;
    v.y = -v.y;
    v.z = -v.z;
  }   
  return v;
}

point3D normalize(point3D v)
{
  double l = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  v.x /= l;
  v.y /= l;
  v.z /= l;
  return v;
}

point3D orthogonal_vector(point3D pole)
{
  point3D o;
  if (equal(abs_double(pole.z), 1)) {
    o.x = 1;
    o.y = 0;
    o.z = 0;
  } else {
    o.x = -pole.y;
    o.y = pole.x;
    o.z = 0;
    o = normalize(o);
  }
  return o;
}

double point3D_angle(point3D a, point3D b)
{
  double dot = a.x * b.x + a.y * b.y + a.z * b.z;
  double mag_a = sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
  double mag_b = sqrt(b.x * b.x + b.y * b.y + b.z * b.z);
  double real_dot = dot / (mag_a * mag_b);
  if (real_dot > 1) real_dot = 1;
  if (real_dot < -1) real_dot = -1;
  return acos(real_dot);
}

void print_point(point3D p)
{
  fprintf(stderr, "%f %f %f\n", p.x, p.y, p.z);
}

point3D projection(point3D a, point3D pole)
{
  double dot = dot_product(a, pole);
  point3D proj;
  proj.x = a.x - dot * pole.x;
  proj.y = a.y - dot * pole.y;
  proj.z = a.z - dot * pole.z; 
  return proj;
}

point3D projection_span(point3D u, point3D v, point3D w) {
  u = normalize(u);
  v = normalize(v);
  double dp_uv = dot_product(u,v);
  point3D v_perp;
  v_perp.x = v.x - u.x * dp_uv;
  v_perp.y = v.y - u.y * dp_uv;
  v_perp.z = v.z - u.z * dp_uv;
  v = normalize(v_perp);
  double dp_uw = dot_product(u,w);
  double dp_vw = dot_product(v,w);
  w.x = v.x * dp_vw + u.x * dp_uw;
  w.y = v.y * dp_vw + u.y * dp_uw;
  w.z = v.z * dp_vw + u.z * dp_uw;
  w = normalize(w);
  return w;
}

point3D random_point_sphere() 
{
  point3D p;
  p.x = 2 * (rand() - RAND_MAX / 2.0) / RAND_MAX;
  p.y = 2 * (rand() - RAND_MAX / 2.0) / RAND_MAX;
  p.z = 2 * (rand() - RAND_MAX / 2.0) / RAND_MAX;
  if (p.x * p.x + p.y * p.y + p.z * p.z <= 1) {
    return normalize(p);
  }
  else {
    return random_point_sphere();
  }
}

double relative_angle(point3D pole, point3D v)
{
  double h = dot_product(pole, v);
  v.x -= pole.x * h;
  v.y -= pole.y * h;
  v.z -= pole.z * h;
  point3D a = orthogonal_vector(pole);    
  double theta = point3D_angle(a, v);
  if (dot_product(pole, cross_product(a, v)) >= 0) {
    return theta;
  } else {
    return -theta;
  }
}

/* Based on Murray and Correia (2010) equations (49-52) */
/* http://en.wikipedia.org/wiki/Rotation_matrix */
point3D rotate_x(point3D p, double phi)
{
  point3D q;
  q.x = p.x;
  q.y = cos(phi) * p.y - sin(phi) * p.z;
  q.z = sin(phi) * p.y + cos(phi) * p.z;
  return q;
}

/* Based on Murray and Correia (2010) equations (49-52) */
/* http://en.wikipedia.org/wiki/Rotation_matrix */
point3D rotate_y(point3D p, double phi)
{
  point3D q;
  q.x = cos(phi) * p.x + sin(phi) * p.z;
  q.y = p.y;
  q.z = - sin(phi) * p.x + cos(phi) * p.z;
  return q;
}

/* Based on Murray and Correia (2010) equations (49-52) */
/* http://en.wikipedia.org/wiki/Rotation_matrix */
point3D rotate_z(point3D p, double phi)
{
  point3D q;
  q.x = cos(phi) * p.x - sin(phi) * p.y;
  q.y = sin(phi) * p.x + cos(phi) * p.y;
  q.z = p.z;
  return q;
}
