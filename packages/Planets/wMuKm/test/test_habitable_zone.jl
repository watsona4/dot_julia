tol = 1e-3
#
# Test Earth-like values against the online calculator.
# https://depts.washington.edu/naivpl/sites/default/files/hz.shtml
#
Teff   = 5780 # Sun's effective temperature.
L_star = 1.0

limits = habitable_zone(Teff, L_star)
@test abs(limits[1] - 0.750) < tol  # Recent Venus.
@test abs(limits[2] - 0.950) < tol  # Runaway Greenhouse.
@test abs(limits[3] - 1.676) < tol  # Maximum Greenhouse.
@test abs(limits[4] - 1.765) < 1e-2 # Early Mars. ---  FIXME (very close.)
@test abs(limits[5] - 0.917) < tol  # Runaway Greenhouse for 5.0 ME.
@test abs(limits[6] - 1.005) < tol  # Runaway Greenhouse for 0.1 ME.

#
# Test an M-dwarf against the online calculator.
# https://depts.washington.edu/naivpl/sites/default/files/hz.shtml
#
Teff   = 3700  # Temperature of a 0.5 M_sun star.
L_star = 0.04  # Luminosity of a 0.5 M_sun star.

limits = habitable_zone(Teff, L_star)
@test abs(limits[1] - 0.163) < tol # Recent Venus.
@test abs(limits[2] - 0.207) < tol # Runaway Greenhouse.
@test abs(limits[3] - 0.398) < tol # Maximum Greenhouse.
@test abs(limits[4] - 0.419) < tol # Early Mars.
@test abs(limits[5] - 0.199) < tol # Runaway Greenhouse for 5.0 ME.
@test abs(limits[6] - 0.219) < tol # Runaway Greenhouse for 0.1 ME.

