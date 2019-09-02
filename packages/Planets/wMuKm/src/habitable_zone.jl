#=
Author: Daniel Carrera (dcarrera@gmail.com)

Compute the habitable zone limits from Kopparapu et al. (2013).
=#

"""
Computes all the limits for the habitable zone from Kopparapu et al. (2013).
This function uses the updated coefficients from their website.

Input:

    Teff       Star's effective temperature (K)
	L_star     Star's luminosity (L_sun)

Example:
	
	Teff   = 3700  # Temperature of a 0.5 M_sun star.
	L_star = 0.04  # Luminosity of a 0.5 M_sun star.
	
	limits = habitable_zone(Teff, L_star)
	
	@info("Recent Venus                  = \$(limits[1]) AU")
	@info("Runaway Greenhouse            = \$(limits[2]) AU")
	@info("Maximum Greenhouse            = \$(limits[3]) AU")
	@info("Early Mars                    = \$(limits[4]) AU")
	@info("Runaway Greenhouse for 5.0 ME = \$(limits[5]) AU")
	@info("Runaway Greenhouse for 0.1 ME = \$(limits[6]) AU")

Citations:
	
	Kopparapu et al. (2013)
	http://adsabs.harvard.edu/abs/2013ApJ...765..131K
	
	Erratum
	http://adsabs.harvard.edu/abs/2013ApJ...770...82K
	
	Updated values
	https://depts.washington.edu/naivpl/sites/default/files/hz.shtml
"""
function habitable_zone(Teff::Number, L_star::Number)
	@assert(Teff >= 2600)
	@assert(Teff <= 7200)
	
	Ts = Teff - 5780
	
	# Table of coefficients from:
	# https://depts.washington.edu/naivpl/sites/default/files/hz.shtml
	#
	# S0 == S_eff_sun
	#
	# i = 1 --> Recent Venus
	# i = 2 --> Runaway Greenhouse
	# i = 3 --> Maximum Greenhouse
	# i = 4 --> Early Mars
	# i = 5 --> Runaway Greenhouse for 5 ME
	# i = 6 --> Runaway Greenhouse for 0.1 ME
	S0 = [ 1.77600e+00   1.10700e+00   3.56000e-01   3.20000e-01   1.18800e+00   9.90000e-01]
	a  = [ 2.13600e-04   1.33200e-04   6.17100e-05   5.54700e-05   1.43300e-04   1.20900e-04]
	b  = [ 2.53300e-08   1.58000e-08   1.69800e-09   1.52600e-09   1.70700e-08   1.40400e-08]
	c  = [-1.33200e-11  -8.30800e-12  -3.19800e-12  -2.87400e-12  -8.96800e-12  -7.41800e-12]
	d  = [-3.09700e-15  -1.93100e-15  -5.57500e-16  -5.01100e-16  -2.08400e-15  -1.71300e-15]
	
	limits = zeros(6)
	for j in 1:6
		Seff = S0[j] + a[j]*Ts + b[j]*Ts^2 + c[j]*Ts^3 + d[j]*Ts^4
		
		limits[j] = sqrt(L_star / Seff) # AU
	end
	
	return limits
end
