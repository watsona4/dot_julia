tol = 1e-10
#
# Test grid points.
#
Teff, L_star, logg = stellar_evolution(0.0900000036,t=1e5,Z=0.01)
@test abs(Teff   - 10^3.4680  ) < tol
@test abs(L_star - 10^(-0.733)) < tol
@test abs(logg   - 2.949) < tol


Teff, L_star, logg = stellar_evolution(0.75,t=1.41e9,Z=0.01)
@test abs(Teff   - 10^3.6942  ) < tol
@test abs(L_star - 10^(-0.606)) < tol
@test abs(logg   - 4.649) < tol

#
# Test interpolation across mass.
#
m = (0.0900000036 + 0.1000000015)/2

Teff, L_star, logg = stellar_evolution(m,t=1e5,Z=0.01)
@test abs(Teff   - 10^((3.4680 + 3.4723)/2) ) < tol
@test abs(L_star - 10^(-(0.733 + 0.658 )/2) ) < tol
@test abs(logg   - (2.949 + 2.937)/2 ) < tol

#
# Test interpolation across time.
#
m = 0.5
t = (1.00e5 + 1.12e+05) / 2

Teff, L_star, logg = stellar_evolution(m,t=t,Z=0.01)
@test abs(Teff   - 10^((3.6132 + 3.6131)/2) ) < tol
@test abs(L_star - 10^((0.557  + 0.543 )/2) ) < tol
@test abs(logg   - (2.985 + 2.999)/2 ) < tol

#
# Test interpolation across metallicity.
#
m = 0.5
t = 1e5
Z = (0.01 + 0.015) / 2

Teff, L_star, logg = stellar_evolution(m,t=t,Z=Z)
@test abs(Teff   - 10^((3.6132 + 3.6034)/2) ) < tol
@test abs(L_star - 10^((0.557  + 0.524 )/2) ) < tol
@test abs(logg   - (2.985 + 2.978)/2 ) < tol

