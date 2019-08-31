#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "transit.h"

/* --- FUNCTION IMPLEMENTATIONS --- */

double chi_planets(double h1, double h2, double phi)
{
    if(equal(phi, 0)) /* 0 / 0 so return a number > 1 */
    {
        return 2;
    }
    else
    {
        return sqrt((h1 * h1 + h2 * h2 - 2 * h1 * h2 * cos(phi))
            / (sin(phi) * sin(phi)));
    }
}

planet_ellipse convert(orbit o)
{
    planet_ellipse p;
    p.use = o.use;
    /* Equation (12) of (Winn, 2010) */
    p.h = o.r_star / o.a * (1 / (1 - o.e * o.e));
    
    double /* h1,*/ h2;
    /* Equation (9) and (10) of (Winn, 2010) */
    // h1  = (o.r_star / o.a) / (1 - o.e);
    h2  = (o.r_star / o.a) / (1 + o.e);
    double phi = PI - (asin(h2) + acos(p.h));
    
    point3D m1, m2;
    m1.x = o.pole.x * sin(phi) + o.periapse.x * cos(phi);
    m1.y = o.pole.y * sin(phi) + o.periapse.y * cos(phi);
    m1.z = o.pole.z * sin(phi) + o.periapse.z * cos(phi);
    m2.x = -o.pole.x * sin(phi) + o.periapse.x * cos(phi);
    m2.y = -o.pole.y * sin(phi) + o.periapse.y * cos(phi);
    m2.z = -o.pole.z * sin(phi) + o.periapse.z * cos(phi);
    
    p.pole[0] = normalize(m1);
    p.pole[1] = normalize(m2);
    
    return p;
}

planet_ellipse convert(orbit o, double adj)
{
    planet_ellipse p;
    p.use = o.use;
    /* Equation (12) of (Winn, 2010) */
    p.h = (o.r_star + adj * o.r) / o.a * (1 / (1 - o.e * o.e));
    
    double /* h1, */ h2;
    /* Equation (9) and (10) of (Winn, 2010) */
    // h1  = (o.r_star / o.a) / (1 - o.e);
    h2  = (o.r_star / o.a) / (1 + o.e);
    double phi = PI - (asin(h2) + acos(p.h));
    
    point3D m1, m2;
    m1.x = o.pole.x * sin(phi) + o.periapse.x * cos(phi);
    m1.y = o.pole.y * sin(phi) + o.periapse.y * cos(phi);
    m1.z = o.pole.z * sin(phi) + o.periapse.z * cos(phi);
    m2.x = -o.pole.x * sin(phi) + o.periapse.x * cos(phi);
    m2.y = -o.pole.y * sin(phi) + o.periapse.y * cos(phi);
    m2.z = -o.pole.z * sin(phi) + o.periapse.z * cos(phi);
    
    p.pole[0] = normalize(m1);
    p.pole[1] = normalize(m2);
    
    return p;
}

planet_ellipse convert_upper_bound(orbit o) {
    planet_ellipse p;
    p.use = o.use;
    
    if (p.use == 1) {
	/* Equation (9) of (Winn, 2010) */
	p.h = (o.r_star / o.a) / (1 - o.e);
    }
    else {
	/* Equation (10) of (Winn, 2010) */
	p.h = (o.r_star / o.a) / (1 + o.e);
    }

    p.pole[0] = o.pole;
    p.pole[1].x = -o.pole.x;
    p.pole[1].y = -o.pole.y;
    p.pole[1].z = -o.pole.z;
    return p;
}

planet_ellipse convert_lower_bound(orbit o) {
    planet_ellipse p;
    p.use = o.use;

    if (p.use == 1) {
	/* Equation (10) of (Winn, 2010) */
	p.h = (o.r_star / o.a) / (1 + o.e);
    }
    else {
	/* Equation (9) of (Winn, 2010) */
	p.h = (o.r_star / o.a) / (1 - o.e);
    }

    p.pole[0] = o.pole;
    p.pole[1].x = -o.pole.x;
    p.pole[1].y = -o.pole.y;
    p.pole[1].z = -o.pole.z;

    return p;
}

int in_hull(point3D point, int n, planet_ellipse p[])
{
    int i;
    for (i = 0; i < n; i++)
    {
        int flag = !in_transit(point, p[i]);
        if (flag)
        {
            return 0;
        }
    }
    return 1;
}

int in_hull_exact(point3D point, int n, orbit o[])
{
    int i;
    for (i = 0; i < n; i++)
    {
        int flag = !in_transit_exact(point, o[i]);
	if (flag)
        {
            return 0;
        }
    }
    return 1;
}

int in_transit(point3D point, planet_ellipse p)
{
    double dot1 = dot_product(point, p.pole[0]);
    double dot2 = dot_product(point, p.pole[1]);
    if (equal(dot1, p.h) || equal(dot2, p.h))
    {
        return 1;
    }
    int flag = (dot1 <= p.h + EPS) && (dot2 <= p.h + EPS);
    return !(p.use ^ flag);
}

int in_transit_exact(point3D point, orbit o)
{
    point3D proj = normalize(projection(point, o.pole));
    double dot = dot_product(proj, o.periapse);
    /* equation (9) of (Winn, 2010) */
    double h = o.r_star / o.a * (1 + o.e * dot) / (1 - o.e * o.e);
    int flag = abs_double(dot_product(point, o.pole)) < h + EPS;
    return !(o.use ^ flag);
}

/* Implementation based on Murray and Correia (2010),  Fabrycky (2010), 
    Solar System Dynamics (Murray and Dermott), and Wikipedia*/
orbit input_orbit_to_orbit(input_orbit io)
{
    orbit o;
    o.use = io.use;
    o.a = io.a;
    o.e = io.e;
    o.r = io.r;
    o.r_star = io.r_star;
    o.pole = new_point3D(0, 0, 1);
    o.periapse = new_point3D(1, 0, 0);
    /* Equation (51) of Murrary and Correia (2010)*/
    o.pole = rotate_z(rotate_x(rotate_z(o.pole, io.omega), io.i), io.Omega);
    o.periapse =
        rotate_z(rotate_x(rotate_z(o.periapse, io.omega), io.i), io.Omega);
    return o;
}

crossing intersection(point3D pole1, double h1, point3D pole2, double h2)
{
    crossing points;
    int n = 0;
    int i;
    int swapxy = 0;
    int swapxz = 0;
    
    if (chi_planets(h1, h2, acos(dot_product(pole1, pole2))) > 1)
    {
        points.num = 0;
        return points;
    }
    
    double y1, y2, z1, z2;
    double A, B, C;
    if (equal(0, -pole1.z * pole2.y + pole2.z * pole1.y))
    {
        double r;
        if (!equal(0, pole1.z * pole2.x - pole2.z  * pole1.x))
        {
            swapxy = 1;
            r       = pole1.x;
            pole1.x = pole1.y;
            pole1.y = r;
            r       = pole2.x;
            pole2.x = pole2.y;
            pole2.y = r;
        }
        else
        {
            swapxz = 1;
            r       = pole1.x;
            pole1.x = pole1.z;
            pole1.z = r;
            r       = pole2.x;
            pole2.x = pole2.z;
            pole2.z = r;
        }
    }
    y1 = (-pole1.x * pole2.z + pole1.z * pole2.x)
        / (-pole1.z * pole2.y + pole2.z * pole1.y);
    y2 = (h1 * pole2.z - h2 * pole1.z)
        / (-pole1.z * pole2.y + pole2.z * pole1.y);
    z1 = (-pole1.x * pole2.y + pole1.y * pole2.x)
        / (pole1.z * pole2.y - pole2.z * pole1.y);
    z2 = (h1 * pole2.y - h2 * pole1.y)
        / (pole1.z * pole2.y - pole2.z * pole1.y);
    A = 1 + y1 * y1 + z1 * z1;
    B = 2 * (y1 * y2 + z1 * z2);
    C = y2 * y2 + z2 * z2 - 1;
    if (B * B >= 4 * A * C)
    {
        double x1, x2;
        x1 = (-B + sqrt(B * B - 4 * A * C)) / (2 * A);
        x2 = (-B - sqrt(B * B - 4 * A * C)) / (2 * A);
        if (abs_double(x1) <= 1)
        {
            points.p[n  ].x = x1;
            points.p[n  ].y = y1 * x1 + y2;
            points.p[n++].z = z1 * x1 + z2;
        }
        if (abs_double(x2) <= 1)
        {
            points.p[n  ].x = x2;
            points.p[n  ].y = y1 * x2 + y2;
            points.p[n++].z = z1 * x2 + z2;
        }
    }
    points.num = n;
    for (i = 0; i < points.num; i++)
    {
        if (swapxy)
        {
            double r      = points.p[i].x;
            points.p[i].x = points.p[i].y;
            points.p[i].y = r;
        }
        if (swapxz)
        {
            double r      = points.p[i].x;
            points.p[i].x = points.p[i].z;
            points.p[i].z = r;
        }
    }
    return points;
}

crossing intersection_all(planet_ellipse a, planet_ellipse b)
{
    crossing all_points;
    all_points.num = 0;
    int i, j = 0, k;
    for (i = 0; i < 4; i++)
    {
        crossing points = intersection(a.pole[i / 2], a.h, b.pole[i % 2], b.h);
        all_points.num += points.num;
        for (k = 0; k < points.num; k++)
        {
            all_points.p[j++] = points.p[k];
        } 
    }
    return all_points;
}

double prob_of_transits_approx(const int n, planet_ellipse p[])
{
    crossing points[n][n];
    int i, j, k;
    vertex hull[8 * n * n];
    // int num_adj[8 * n];
    int size_hull = 0;
    int num_points[n][2];
    int correct_flag = 1;
    for (i = 0; i < n; i++)
    {
        correct_flag *= 1 - p[i].use;
        for (j = 0; j < 2; j++)
        {
            num_points[i][j] = 0;
        }
    }
    double geodesic_curvature = 0;
    double turning_angles = 0;
    int euler_chi = 0;
    /*Find all points on the hull*/
    for (i = 0; i < n; i++)  
    {
        for (j = i + 1; j < n; j++)
        {
            points[i][j] = intersection_all(p[i], p[j]);
            points[j][i] = points[i][j];
            for (k = 0; k < points[i][j].num; k++)
            {
                if (in_hull(points[i][j].p[k], n, p))
                {
                    hull[size_hull  ].pole[0] = i;
                    hull[size_hull  ].pole[1] = j;
                   
                    hull[size_hull++].p       = points[i][j].p[k];
                }
                if(equal(dot_product(points[i][j].p[k], p[i].pole[0]), p[i].h))
                {
                    num_points[i][0]++;
                }
                else
                {
                    num_points[i][1]++;
                }
                if(equal(dot_product(points[i][j].p[k], p[j].pole[0]), p[j].h))
                {
                    num_points[j][0]++;
                }
                else
                {
                    num_points[j][1]++;
                }
            }
        }
    }
    
    /*Finds boundary curves of the hull disconected with everything else*/
    for (i = 0; i < n; i++) 
    {
        for (j = 0; j < 2; j++)
        {
            if (num_points[i][j] == 0)
            {
                point3D a = point3D_from_angle(p[i], 0, j);
                int flag = in_hull(a, n, p);
                geodesic_curvature += (2 * p[i].use - 1) * p[i].h * 2 * PI
                    * (flag);
                /* euler_chi += 2*flag; */
            }
        }
    }
    
    /*We can stop now if there are no intersection points*/
    if (size_hull == 0) 
    {
        double prob = geodesic_curvature / 4 / PI;
        /* floor(): <http://en.wikipedia.org/wiki/C_mathematical_functions> */
        double ans = prob;
        ans = ans - floor(ans);
        if (ans > .5)
        {
            ans -= .5;
        }
        if (correct_flag == 1)
        {
            double other_prob = prob_of_transits_approx_monte_carlo(n, p, 30);
            if (other_prob - ans > .25) ans += .5;
        }
        return ans;
    }
    
    /* int pa[size_hull]; // union-find
    for (i = 0; i < size_hull; i++)
    {
        pa[i] = i;
    } */
    
    /*Sorts points based on relative angle*/
    for (i = 0; i < n; i++) 
    {
        int list[2][4 * n];
        double angle[2][4 * n];
        int len[2];
        len[0] = 0;
        len[1] = 0;
        for (j = 0; j < size_hull; j++)
        {
            for (k = 0; k < 2; k++)
            {
                if (hull[j].pole[k] == i)
                {
                    if (equal(dot_product(hull[j].p, p[i].pole[0]), p[i].h))
                    {
                        hull[j].index[k] = 0;
                        angle[0][len[0]] = relative_angle(p[i].pole[0], hull[j].p);
                        list[0][len[0]++] = j;
                    }
                    else
                    {
                        hull[j].index[k] = 1;
                        angle[1][len[1]] = relative_angle(p[i].pole[1], hull[j].p);
                        list[1][len[1]++] = j;
                    }
                }
            }
        }
        /*sort list based on value in angle*/
        for (j = 0; j < 2; j++)
        {
            for (k = 0; k < len[j]; k++)
            {
                int l;
                for (l = 0; l < k; l++)
                {
                    double a;
                    int b;
                    if (angle[j][k] < angle[j][l])
                    {
                        a           = angle[j][k];
                        angle[j][k] = angle[j][l];
                        angle[j][l] = a;
                        b           = list[j][k];
                        list[j][k]  = list[j][l];
                        list[j][l]  = b;
                    }
                }
            }
        }
        for (j = 0; j < 2; j++)
        {
            int good_arc;
            point3D a = point3D_from_angle(p[i], (angle[j][1] + angle[j][0]) / 2,
                j);
            good_arc = 1 - in_hull(a, n, p);
            for (k = 0; k < len[j]; k++)
            {
                if (k % 2 == good_arc)
                {
		  // int k1 = (k + 1) % len[j];
                    /* while (pa[list[j][k]] != pa[pa[list[j][k]]])
                    {
                        pa[list[j][k]] = pa[pa[list[j][k]]];
                    }
                    while (pa[list[j][k1]] != pa[pa[list[j][k1]]])
                    {
                        pa[list[j][k1]] = pa[pa[list[j][k1]]];
                    }
                    pa[list[j][k]] = pa[pa[list[j][k1]]]; */
                    geodesic_curvature += (2 * p[i].use - 1) *
                        (angle[j][(k + 1) % len[j]] + 2 * PI *
                        (k + 1 == len[j]) - angle[j][k]) * p[i].h;
                }
            }
        }
    }
    
    /* for (i = 0; i < size_hull; i++)
    {
        while (pa[i] != pa[pa[i]])
        {
            pa[i] = pa[pa[i]];
        }
    }
    
    for (i = 0; i < size_hull; i++)
    {
        if (pa[i] == -1) continue;
        if (pa[pa[i]] == -1) continue;
        euler_chi++;
        pa[pa[i]] = -1;
    } */
    
    /*caculates turning angles*/
    for (i = 0; i < size_hull; i++) 
    {
        turning_angles += (2 * p[hull[i].pole[0]].use - 1) *
            (2 * p[hull[i].pole[1]].use - 1) *
            point3D_angle(normal_point3D(hull[i].p,
                p[hull[i].pole[0]].pole[hull[i].index[0]]),
                normal_point3D(hull[i].p,
                p[hull[i].pole[1]].pole[hull[i].index[1]]));
    }

    double prob = (geodesic_curvature - turning_angles) / 4 / PI;
    prob += euler_chi / 2.0;
    /* if (equal(0, prob)) return 0; */
    /* floor(): <http://en.wikipedia.org/wiki/C_mathematical_functions> */
    double ans = prob - floor(prob);
    if (ans > .5)
    {
        ans -= .5;
    }
    if (correct_flag == 1)
    {
        double other_prob = prob_of_transits_approx_monte_carlo(n, p, 30);
        if (other_prob - ans > .25) ans += .5;
    }
    return ans;
}

double prob_of_transits_approx_monte_carlo(const int n, planet_ellipse p[], int n_trials)
{
    int n_good = 0;
    int i;
    for (i = 0; i < n_trials; i++)
    {
        point3D a = random_point_sphere();
        if (in_hull(a, n, p))
        {
            n_good++;
        }
    }
    return 1.0 * n_good / n_trials;
}

sci_value prob_of_transits_input_orbit(const int n, input_orbit io[]) {
    planet_ellipse p[n];
    double prob, prob_up, prob_lo;
    int i = 0;
    for (; i < n; i++) {
	p[i] = convert(input_orbit_to_orbit(io[i]));
    }
    prob = prob_of_transits_approx(n, p);
    for (i = 0; i < n; i++) {
	p[i] = convert_upper_bound(input_orbit_to_orbit(io[i]));
    }
    prob_up = prob_of_transits_approx(n, p);
    for (i = 0; i < n; i++) {
	p[i] = convert_lower_bound(input_orbit_to_orbit(io[i]));
    }
    prob_lo = prob_of_transits_approx(n, p);
    return sci_value(prob, prob_up - prob, prob - prob_lo);
}

sci_value prob_of_transits_orbit(const int n, orbit o[]) {
    planet_ellipse p[n];
    double prob, prob_up, prob_lo;
    int i = 0;
    for (; i < n; i++) {
        p[i] = convert(o[i]);
    }
    prob = prob_of_transits_approx(n, p);
    for (i = 0; i < n; i++) {
        p[i] = convert_upper_bound(o[i]);
    }
    prob_up = prob_of_transits_approx(n, p);
    for (i = 0; i < n; i++) {
        p[i] = convert_lower_bound(o[i]);
    }
    prob_lo = prob_of_transits_approx(n, p);
    return sci_value(prob, prob_up - prob, prob - prob_lo);
}

double prob_of_transits_monte_carlo(const int n, orbit o[], int n_trials)
{
    int n_good = 0;
    int i;
    for (i = 0; i < n_trials; i++)
    {
        point3D a = random_point_sphere();
        if (in_hull_exact(a, n, o))
        {
            n_good++;
        }
    }
    return 1.0 * n_good / n_trials;
}

point3D point3D_from_angle(planet_ellipse p, double angle, int sign)
{
    point3D a = orthogonal_vector(p.pole[sign]);
    point3D b = cross_product(p.pole[sign], a);
    point3D v;
    v.x = cos(angle) * a.x + sin(angle) * b.x;
    v.y = cos(angle) * a.y + sin(angle) * b.y;
    v.z = cos(angle) * a.z + sin(angle) * b.z;
    v.x *= sqrt(1 - p.h * p.h);
    v.y *= sqrt(1 - p.h * p.h);
    v.z *= sqrt(1 - p.h * p.h);
    v.x += p.pole[sign].x * p.h;
    v.y += p.pole[sign].y * p.h;
    v.z += p.pole[sign].z * p.h;
    return v;
}
