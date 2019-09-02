#MDDatasets: Additional array/vector operations
#-------------------------------------------------------------------------------
#=NOTE:
These tools should eventually be moved to a separate unit.
=#


#==Iterators
===============================================================================#
#Obtain an array iterator:
subscripts(sz::Tuple) = [Tuple(x) for x in CartesianIndices(sz)]
subscripts(a::Array) = [Tuple(x) for x in CartesianIndices(a)]


#==Useful tests
===============================================================================#

#Verifies that v is strictly increasing (no repeating values):
function isincreasing(v::Vector)
	prev = v[1]
	for x in v[2:end]
		if x <= prev
			return false
		end
	end
	return true
end

isincreasing(r::AbstractRange) = (step(r) > 0)


#==Validation functions (throw exceptions)
===============================================================================#


#==Helper functions
===============================================================================#

#Assumes vector is ordered... Not currently checking that it is true..
function findclosestindex(v::Vector, val)
	reltol =  1/1000 #WANTCONST
	if length(v) < 2
		if abs(1-val/v[1]) < reltol
			return 1
		else
			throw("Value not found: $val")
		end
	end
	vlast = v[2] #Gets an order of magnitude for first point
	for idx in 1:length(v)
		Δ = abs(v[idx] - vlast)
		if abs(val-v[idx]) < reltol*Δ
			return idx
		end
		vlast = v[idx]
	end
	throw("Value not found: $val")
end

#Create vector with data left-shifted by n (padded with 0s)
function _lshift(v::Vector, n::Int)
	@assert(n >= 0, "Cannot shfit by a negative number")
	result = zeros(v)
	for i in 1:(length(v)-n)
		result[i] = v[i+n]
	end
	return result
end

#Create vector with data right-shifted by n (padded with 0s)
function _rshift(v::Vector, n::Int)
	@assert(n >= 0, "Cannot shfit by a negative number")
	result = zero(v)
	for i in length(v):-1:(1+n)
		result[i] = v[i-n]
	end
	return result
end

#Create vector with data shifted by +/-n (padded with 0s)
function shift(v::Vector, n::Int)
	if n >= 0
		return _rshift(v, n)
	else
		return _lshift(v, -n)
	end
end

#Compute difference between two adjacent points:
#TODO: optimize operations so they run faster
function delta(v::Vector)
	return v[2:end] .- v[1:end-1]
end

#Compute mean of two adjacent points:
#TODO: optimize operations so they run faster
function meanadj(v::Vector)
	return (v[1:end-1] .+ v[2:end])./2
end

#Last line
