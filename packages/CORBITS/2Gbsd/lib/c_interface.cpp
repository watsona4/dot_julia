#include "transit.h"

// external interface for C, Julia, etc.
extern "C" {
void prob_of_transits_arrays(double a[], double r_star, double r[], double e[], double Omega[], double omega[], double inc[], int use[], int n_pl, double output[])
{
  orbit orb[n_pl];
  for(int i=0;i<n_pl;++i)
    {
    orb[i].use = use[i];
    orb[i].a = a[i];
    orb[i].e = e[i];
    orb[i].r = r[i];
    orb[i].r_star = r_star;
    orb[i].pole = new_point3D(0, 0, 1);
    orb[i].periapse = new_point3D(1, 0, 0);
    /* Equation (51) of Murrary and Correia (2010)*/
    orb[i].pole = rotate_z(rotate_x(rotate_z(orb[i].pole, omega[i]), inc[i]), Omega[i]);
    orb[i].periapse =
        rotate_z(rotate_x(rotate_z(orb[i].periapse, omega[i]), inc[i]), Omega[i]);
    }
  sci_value out = prob_of_transits_orbit(n_pl, orb);
  output[0] = out.val;
  output[1] = out.pos_err;
  output[2] = out.neg_err;
}

double prob_of_transits_approx_arrays(double a[], double r_star, double r[], double e[], double Omega[], double omega[], double inc[], int use[], int n_pl)
{
  orbit orb[n_pl];
  planet_ellipse p[n_pl];
   for(int i=0;i<n_pl;++i)
    {
    orb[i].use = use[i];
    orb[i].a = a[i];
    orb[i].e = e[i];
    orb[i].r = r[i];
    orb[i].r_star = r_star;
    orb[i].pole = new_point3D(0, 0, 1);
    orb[i].periapse = new_point3D(1, 0, 0);
    /* Equation (51) of Murrary and Correia (2010)*/
    orb[i].pole = rotate_z(rotate_x(rotate_z(orb[i].pole, omega[i]), inc[i]), Omega[i]);
    orb[i].periapse =
        rotate_z(rotate_x(rotate_z(orb[i].periapse, omega[i]), inc[i]), Omega[i]);
    p[i] = convert(orb[i]);
    }
 return prob_of_transits_approx(n_pl, p);
}

double prob_of_transits_approx_monte_carlo_arrays(double a[], double r_star, double r[], double e[], double Omega[], double omega[], double inc[], int use[], int n_pl, int n_trials)
{
  orbit orb[n_pl];
  planet_ellipse p[n_pl];
   for(int i=0;i<n_pl;++i)
    {
    orb[i].use = use[i];
    orb[i].a = a[i];
    orb[i].e = e[i];
    orb[i].r = r[i];
    orb[i].r_star = r_star;
    orb[i].pole = new_point3D(0, 0, 1);
    orb[i].periapse = new_point3D(1, 0, 0);
    /* Equation (51) of Murrary and Correia (2010)*/
    orb[i].pole = rotate_z(rotate_x(rotate_z(orb[i].pole, omega[i]), inc[i]), Omega[i]);
    orb[i].periapse =
        rotate_z(rotate_x(rotate_z(orb[i].periapse, omega[i]), inc[i]), Omega[i]);
    p[i] = convert(orb[i]);
    }
 return prob_of_transits_approx_monte_carlo(n_pl, p, n_trials);
}

double prob_of_transits_monte_carlo_arrays(double a[], double r_star, double r[], double e[], double Omega[], double omega[], double inc[], int use[], int n_pl, int n_trials)
{
  orbit orb[n_pl];
   for(int i=0;i<n_pl;++i)
    {
    orb[i].use = use[i];
    orb[i].a = a[i];
    orb[i].e = e[i];
    orb[i].r = r[i];
    orb[i].r_star = r_star;
    orb[i].pole = new_point3D(0, 0, 1);
    orb[i].periapse = new_point3D(1, 0, 0);
    /* Equation (51) of Murrary and Correia (2010)*/
    orb[i].pole = rotate_z(rotate_x(rotate_z(orb[i].pole, omega[i]), inc[i]), Omega[i]);
    orb[i].periapse =
        rotate_z(rotate_x(rotate_z(orb[i].periapse, omega[i]), inc[i]), Omega[i]);
    }
 return prob_of_transits_monte_carlo(n_pl, orb, n_trials);
}

} // end extern "C"

#if 0
extern "C" {
// For testing accessor functions for trying to interface C++ structs to Julia directly
// For now, easier to just wrap all of this inside the C interface
double get_a(input_orbit io) { return io.a; }
double get_r_star(input_orbit io) { return io.r_star; }
double get_r(input_orbit io) { return io.r; }
double get_e(input_orbit io) { return io.e; }
double get_P(input_orbit io) { return io.P; }
double get_Omega(input_orbit io) { return io.Omega; }
double get_omega(input_orbit io) { return io.omega; }
double get_i(input_orbit io) { return io.i; }
int get_use(input_orbit io) { return io.use; }

// From when I was testing passing pointers between C and Julia
double get_arr(double in[], int n) { return in[n-1]; }
double get_val(double *in) { return *in; }
double set_val(double *out, double in) { *out = in; return *out; }
void set_vals(double *out, double *in, int n) { for(int i=0;i<n;++i) out[i] = in[i];  }
//double get_val(double &in) { return in; }
//double set_val(double &out, double in) { out = in; return out; }
}
#endif

