#InspectDR: Basic math operations
#-------------------------------------------------------------------------------
#=NOTE:
These tools should eventually be moved to a separate unit.
=#


#==Useful tests
===============================================================================#

#Verifies that v is strictly increasing (no repeating values):
#TODO: support repeating values (non-strict)
function isincreasing(v::Vector)
	if length(v) < 1; return true; end
	prev = v[1]

	for x in v[2:end]
		if !(x > prev) #Make sure works for NaN
			return false
		end
	end
	return true
end

isincreasing(r::AbstractRange) = (step(r) > 0)

#==Basic operations
===============================================================================#

#Safe version of extrema (returns DNaN on error):
#Also ignores NaNs.  TODO: optimize?
function extrema_nan(v::Vector)
	vmin = DInf; vmax = -DInf
	for elem in v
		if !isnan(elem)
			if elem > vmax
				vmax = elem
			end
			if elem < vmin
				vmin = elem
			end
		end
	end
	if vmin>vmax
		vmin = vmax = DNaN
	end
	return (vmin, vmax)
end
#Last line
