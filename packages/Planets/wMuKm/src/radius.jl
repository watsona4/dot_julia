#=
Author: Daniel Carrera (dcarrera@gmail.com)

Compute the core radius using the table from Zeng et al (2016).
http://adsabs.harvard.edu/abs/2016ApJ...819..127Z

In general I'll use a bi-linear interpolation on the table from
Zeng et al. But if the mass is out of range, I'll use R ~ M^(1/3.7)
(also from Zeng et al.) I don't expect that to happen very often.
=#
using DataFrames
using Missings
using CSV

#####################
#
# COMPUTE PLANET RADII
#
#####################
#
# I specify the column names by hand because CSV.read keeps adding spaces
# to the column names.
#
mr_names = Symbol[]
append!(mr_names, [:Mearth])
append!(mr_names, map(p -> Symbol("$(p)%fe"), 100:-5:5))
append!(mr_names, [:rocky])
append!(mr_names, map(p -> Symbol("$(p)%h2o"), 5:5:100))

mr_table = "$(@__DIR__)/../data/Zeng_2016_MR_table.tsv"
mr_table = CSV.read(mr_table, datarow=2, header=mr_names, delim='\t')

"""
Compute the core radius for either a rock-iron or water-rock core.

Examples:

	#
	# Radius of a 3.0 M_earth core with 10% water + 90% rock:
	#
	radius = core_radius(3.0, h2o=0.1) # In Earth radii.

	#
	# Radius of a 3.0 M_earth core with 10% iron + 90% rock:
	#
	radius = core_radius(3.0, fe=0.1) # In Earth radii.

Citation:
	
	Zeng et al (2016)
	http://adsabs.harvard.edu/abs/2016ApJ...819..127Z
"""
function core_radius(mass; h2o=0.0, fe=0.0)::Float64
	global mr_table
	@assert(mass > 0)
	@assert(h2o >= 0)
	@assert(h2o <= 1)
	@assert(fe >= 0)
	@assert(fe <= 1)
	
	if (h2o > 0) && (fe > 0)
		@error("h2o and fe fractions cannot both be positive.")
	end
	
	#
	# Column names.
	#
	local p1, p2, c1, c2
	if (h2o == 0) && (fe == 0)
		p1 = p2 = 0
		c1 = c2 = :rocky
	else
		p   = (h2o > 0 ?  h2o  :  fe ) * 100
		mat = (h2o > 0 ? "h2o" : "fe")
		
		p1 = floor(Int, p / 5) * 5
		p2 = ceil( Int, p / 5) * 5
		
		c1 = p1 == 0 ? :rocky : Symbol("$(p1)%$(mat)")
		c2 = p2 == 0 ? :rocky : Symbol("$(p2)%$(mat)")
	end
	#=
	NOTE:	I considered collapsing the `if` below and just making sure
			that p1 != p2. But when you add the extra lines to deal with
			the :rocky column and fe vs h2o columns, I'm not sure that
			the code would look any better.
	=#
	
	#
	# (Single column) ?
	#
	if c1 == c2
		col = c1
		#
		# (Single colum) AND (Mass out of bounds) ?
		# 		=> Extrapolate.
		#
		if mass <= mr_table[1,:Mearth]
			return mr_table[1,col] * (mass/mr_table[1,:Mearth])^(1/3.7)
		end
		if mass >= mr_table[end,:Mearth]
			return mr_table[end,col] * (mass/mr_table[end,:Mearth])^(1/3.7)
		end
		#
		# (Single colum) AND NOT (Mass out of bounds)
		# 		=> Interpolate.
		#
		row1 = sum(mr_table[:Mearth] .< mass)
		row2 = row1 + 1
		
		mass1 = mr_table[row1, :Mearth]
		mass2 = mr_table[row2, :Mearth]
		
		R1 = mr_table[row1, col]
		R2 = mr_table[row2, col]
		
		return R1 * (mass - mass2)/(mass1 - mass2) + R2 * (mass - mass1)/(mass2 - mass1)
	else
		#
		# NOT (Single column)
		#
		col1 = c1
		col2 = c2
		#
		# NOT (Single column) AND (Mass out of bounds) ?
		# 		=> Interpolate + Extrapolate.
		#
		if mass <= mr_table[1,:Mearth]
			R1 = mr_table[1,col1]
			R2 = mr_table[1,col2]
			
			R = R1 * (p - p2)/(p1 - p2) + R2 * (p - p1)/(p2 - p1)
			return R * (mass/mr_table[1,:Mearth])^(1/3.7)
		end
		if mass >= mr_table[end,:Mearth]
			
			R1 = mr_table[end,col1]
			R2 = mr_table[end,col2]
			
			R = R1 * (p - p2)/(p1 - p2) + R2 * (p - p1)/(p2 - p1)
			return R * (mass/mr_table[end,:Mearth])^(1/3.7)
		end
		#
		# NOT (Single column) AND NOT (Mass out of bounds)
		# 		=> Bi-linear interpolation.
		#
		row1 = sum(mr_table[:Mearth] .< mass)
		row2 = row1 + 1
		
		mass1 = mr_table[row1, :Mearth]
		mass2 = mr_table[row2, :Mearth]
		
		R11 = mr_table[row1, col1] # (row,col) -- (mass, h2o or fe)
		R12 = mr_table[row1, col2] # (row,col) -- (mass, h2o or fe)
		R21 = mr_table[row2, col1] # (row,col) -- (mass, h2o or fe)
		R22 = mr_table[row2, col2] # (row,col) -- (mass, h2o or fe)
		
		R = 0.0
		R += R11 * (mass - mass2)/(mass1 - mass2) * (p - p2)/(p1 - p2)
		R += R12 * (mass - mass2)/(mass1 - mass2) * (p - p1)/(p2 - p1)
		R += R21 * (mass - mass1)/(mass2 - mass1) * (p - p2)/(p1 - p2)
		R += R22 * (mass - mass1)/(mass2 - mass1) * (p - p1)/(p2 - p1)
		return R
	end
end
