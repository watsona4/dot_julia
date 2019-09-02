#=
Author: Daniel Carrera (dcarrera@gmail.com)

Compute the accretion rate onto a small (up to Neptune size) planet
embedded in a protoplanetary disk.
=#

"""
Compute the gas accretion rate onto a planet, up to Neptune size, embedded
in a protoplanetary disk. This function implements Equation (B36) derived in
Carrera et al. (2018) which itself is adapted from Ginzburg et al. (2016).

**NOTE**: Equation (B36) of Carrera et al. is in units of M_earth/Myr but
this function returns values in untis of M_earth/year.

**NOTE**: The accretion rate for a planet with zero atmosphere diverges. You
need to initialize the planet's atmosphere to a non-zero value. A reasonable
choice is the gas mass contained inside the planet's Bondi radius. Furthermore,
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
	
Citation:
	
	Carrera et al. (2018) and Ginzburg et al. (2016)
	
	http://adsabs.harvard.edu/cgi-bin/bib_query?arXiv:1804.05069
	http://adsabs.harvard.edu/abs/2016ApJ...825...29G

### Initializing the planet's atmosphere:

	ρ = ... # Local disk gas density in g/cm^3
	T = ... # Local disk gas temperature in Kelvin
	
	M_core = ... # Core mass in M_earth
	
	Rb = 2.861e7 * M_core / T # Bondi radius in cm
	
	M_atm = ρ * Rb^3 * 1.6744e-28 # Initial atmosphere mass in M_earth
"""
function accretion_rate(M_core::Number, M_atm::Number, T::Number)
	return (4.5e-10 / M_atm) * M_core^3.625 / sqrt(T/1000)
end

