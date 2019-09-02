[![Build Status](https://travis-ci.com/dcarrera/Planets.jl.svg?branch=master)](https://travis-ci.com/dcarrera/Planets.jl)

# Planets.jl
This package provides functions related to the formation and properties of
planets. There are formulas to compute the gas accretion rate onto a planet,
the core radius of the planet, and the location of the habitable zone. All the
formulas are taken from peer reviewed publications in astronomy journals, and
links to the [Astrophysics Data System (ADS)](http://adsabs.harvard.edu/) are
included in the documentation.

## Installation

`Planets.jl` requires Julia v1.0 or later, as well the packages [CSV](https://github.com/JuliaData/CSV.jl) 0.4.2 or later, [Missings](https://github.com/JuliaData/Missings.jl), and [DataFrames](https://github.com/JuliaData/DataFrames.jl). To install this package run `] add Planets` on the Julia REPL.

## `core_radius`

This function computes the radius of a planetary core made of either pure
silicate rock, a rock-iron mix, or a rock-water mix. Cores with all three
components are not supported. The function interpolates across the planet
structure grid model of [Zeng et al (2016)](http://adsabs.harvard.edu/abs/2016ApJ...819..127Z), which is publicly available from
[Li Zeng's website](https://www.cfa.harvard.edu/~lzeng/planetmodels.html#mrtables).

Examples:

	#
	# Radius of a 3.0 M_earth core with 10% water + 90% rock:
	#
	radius = core_radius(3.0, h2o=0.1) # In Earth radii.

	#
	# Radius of a 3.0 M_earth core with 10% iron + 90% rock:
	#
	radius = core_radius(3.0, fe=0.1) # In Earth radii.

Citation: [Zeng et al (2016)](http://adsabs.harvard.edu/abs/2016ApJ...819..127Z)

## `accretion_rate`

Compute the gas accretion rate onto a planet, up to Neptune size, embedded
in a protoplanetary disk. This function implements Equation (B36) derived in
[Carrera et al. (2018)](http://adsabs.harvard.edu/abs/2018ApJ...866..104C)
which itself is adapted from
[Ginzburg et al. (2016)](http://adsabs.harvard.edu/abs/2016ApJ...825...29G).

**NOTE**: Equation (B36) of Carrera et al. is in units of M_earth/Myr but
this function returns values in untis of M_earth/year.

**NOTE**: The accretion rate for a planet with zero atmosphere diverges. You
need to initialize the planet's atmosphere to a non-zero value. Furthermore,
the accretion rate is initially very high and small timesteps are required to
resolve the accretion correctly.

Example:

	#
	# Gas accretion rate (units: M_earth / year) for a small planet embedded
	# in a protoplanetary disk.
	#
	# Inputs:
	#
	M_core = 8.0  # Planet's core mass in Earth masses.
	M_atm = 0.02  # Planet's current H2 mass in Earth masses.
	T_disk = 500  # Local disk temperature in Kelvin.
	
	M_atm_dot = accretion_rate(M_core, M_atm, T_disk) # M_earth / year.
	
Citations:
[Carrera et al. (2018)](http://adsabs.harvard.edu/abs/2018ApJ...866..104C)
and
[Ginzburg et al. (2016)](http://adsabs.harvard.edu/abs/2016ApJ...825...29G)

## `stellar_evolution`

Compute the stellar evolution tracks (luminosity, temperature, logg) for
AFGKM with a metallicity of Z = 1.0%, up to an age of 0.89 Gyr, using the
stellar models of [Marigo et al. (2017)](http://adsabs.harvard.edu/abs/2017ApJ...835...77M). This function the following values:

	Teff     Star's effective temperature (K)
	L_star   Log base 10 of the stellar luminosity (L_sun)
	logg     Log gravity.

Example:

	M_star = 0.5 # Stellar mass (M_sun)
	age = 1e9    # Stellar age (years)
	Z = 0.01     # Metallicity
	
	Teff, L_star, logg = stellar_evolution(M_star,t=age,Z=Z)
	
Citation: [Marigo et al. (2017)](http://adsabs.harvard.edu/abs/2017ApJ...835...77M)

See also: [Web interface](http://stev.oapd.inaf.it/cgi-bin/cmd)
	

## `habitable_zone`

Computes all the limits for the habitable zone from [Kopparapu et al. (2013)](http://adsabs.harvard.edu/abs/2013ApJ...765..131K). This function uses the updated coefficients from their website.

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

Citation: [Kopparapu et al. (2013)](http://adsabs.harvard.edu/abs/2013ApJ...765..131K)

See also: [Updated values](https://depts.washington.edu/naivpl/sites/default/files/hz.shtml)

