#=
Author: Daniel Carrera (dcarrera@gmail.com)

=#
using DataFrames
using Statistics
using Printf
using CSV

#
# Start with empty data frames and load them only as needed.
#
parsec = Dict(
	"Z05" => DataFrame(),
	"Z10" => DataFrame(),
	"Z15" => DataFrame(),
	"Z20" => DataFrame()
)

##################################################
#
# INTERNAL FUNCTIONS
#
##################################################
"""
This is an internal function (not exported). It is used to load one of
the stellar evolution tables from the data/ directory. The caller is
responsible for supplying a valid table name:
	
	"Z05"	,	"Z10"	,	"Z15"	,	"Z20"
	
The data is saved as a data frame inside the global variable `parsec[...]`.
If the data was previously loaded, it won't be loaded again, so it's safe
to call this function many times.

Example:

	load_parsec("Z05")
	
	... now parsec["Z05"] contains data.
"""
function load_parsec(s::String)
	if size(parsec[s],1) == 0
		columns = [:t, :Mini, :logL, :logTe, :logg]
		path    = "$(@__DIR__)/../data/PARSEC_Isochrones_$(s).dat"
		parsec[s] = CSV.read(path, datarow=9, header=columns)
	end
end
#=
WARNING:	The list of masses changes with time. The models do not
			form a clean (t,m) grid, so I need to get the mass limits
			separately for each time slot.
=#
function interpolate_mass(df,m)
	cols = [:t, :Mini, :logL, :logTe, :logg]
	ms = df[:Mini]
	m1 = maximum(ms[ms .<= m])  # Lower bound = Highest mass < m.
	m2 = minimum(ms[ms .>= m])  # Upper bound = Lowest mass > m.
	
	df_m1 = df[ms .== m1, cols]
	df_m2 = df[ms .== m2, cols]
	
	@assert(size(df_m1,1) == 1)
	@assert(size(df_m2,1) == 1)
	#
	# Do the interpolation.
	#
	ys = Dict()
	for col in [:logL, :logTe, :logg]
		y_m1 = df_m1[1,col]
		y_m2 = df_m2[1,col]
		
		if m1 == m2
			@assert(y_m1 == y_m2)
			ys[col] = y_m1
		else
			ys[col] = y_m1*(m - m2)/(m1 - m2) +  y_m2*(m - m1)/(m2 - m1)
		end
	end
	return ys
end
function interpolate_time_and_mass(df,m,t)
	cols = [:t, :Mini, :logL, :logTe, :logg]
	#
	# Find the slice with times nearest to `t`.
	#
	ts = df[:t]
	t1 = maximum(ts[ts .<= t]) # Lower bound = Highest time < t.
	t2 = minimum(ts[ts .>= t]) # Upper bound = Lowest time > t.
	#
	# Interpolate along mass separately for each time slot.
	#
	y_t1 = interpolate_mass(df[ts .== t1, cols],m)
	y_t2 = interpolate_mass(df[ts .== t2, cols],m)
	#
	# Do the interpolation.
	#
	ys = Dict()
	for col in [:logL, :logTe, :logg]
		y1 = y_t1[col]
		y2 = y_t2[col]
		
		if t1 == t2
			@assert(y1 == y2)
			ys[col] = y1
		else
			ys[col] = y1*(t - t2)/(t1 - t2) +  y2*(t - t1)/(t2 - t1)
		end
	end
	return ys
end


##################################################
#
# EXPORTED FUNCTIONS
#
##################################################
"""
Compute the stellar evolution tracks (luminosity, temperature, logg) for
AFGKM with a metallicity of Z = 1.0%, up to an age of 0.89 Gyr, using the
stellar models of Marigo et al. (2017). This function the following values:

	Teff     Star's effective temperature (K)
	L_star   Log base 10 of the stellar luminosity (L_sun)
	logg     Log gravity.

Example:

	M_star = 0.5 # Stellar mass (M_sun)
	age = 1e9    # Stellar age (years)
	Z = 0.01     # Metallicity
	
	Teff, L_star, logg = stellar_evolution(M_star,t=age,Z=Z)
	
Citation:
	
	Marigo et al. (2017)
	http://stev.oapd.inaf.it/cgi-bin/cmd
	http://adsabs.harvard.edu/abs/2017ApJ...835...77M
"""
function stellar_evolution(m::Number;t::Number=1e9,Z::Number=0.01)
	@assert(t >= 1e5)
	@assert(t <= 1.26e10)
	@assert(Z >= 0.005)
	@assert(Z <= 0.020)
	#
	# Metallicity between Z1 and Z2.
	#
	Z1 = floor(Int,Z / 0.005) * 0.005
	Z2 = ceil( Int,Z / 0.005) * 0.005
	
	s1 = @sprintf("Z%02d", Z1 * 1000)
	s2 = @sprintf("Z%02d", Z2 * 1000)
	
	load_parsec(s1)
	load_parsec(s2)
	#
	# Interpolate along time and mass for each metallicity.
	#
	y_Z1 = interpolate_time_and_mass(parsec[s1],m,t)
	y_Z2 = interpolate_time_and_mass(parsec[s2],m,t)
	#
	# Do the interpolation.
	#
	ys = Dict()
	for col in [:logL, :logTe, :logg]
		y1 = y_Z1[col]
		y2 = y_Z2[col]
		
		if Z1 == Z2
			@assert(y1 == y2)
			ys[col] = y1
		else
			ys[col] = y1*(Z - Z2)/(Z1 - Z2) +  y2*(Z - Z1)/(Z2 - Z1)
		end
	end
	#
	# Return the final results.
	#
	return 10^ys[:logTe], 10^ys[:logL], ys[:logg]
end

