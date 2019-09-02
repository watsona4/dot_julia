#MDDatasets DataRS (Recursive Sweep) defninitions
#-------------------------------------------------------------------------------

#==Main types
===============================================================================#

#Linked-list representation of multi-dimensional datasets:
#-------------------------------------------------------------------------------
mutable struct DataRS{T} <: DataMD
	sweep::PSweep
	elem::Vector{T}

	function DataRS{T}(sweep::PSweep, elem::Vector{T}) where {T}
		if !elemallowed(DataRS, eltype(elem))
			msg = "Can only create DataRS{T} for T ∈ {DataRS, DataF1, DataFloat, DataInt, DataComplex}"
			throw(ArgumentError(msg))
		elseif length(sweep) != length(elem)
			throw(ArgumentError("sweep length does not match number of elem"))
		end
		return new(sweep, elem)
	end
end

#Shorthand (because default (non-parameterized) constructor was overwritten):
DataRS(sweep::PSweep, elem::Vector{T}) where T = DataRS{T}(sweep, elem)

elemallowed(::Type{DataRS}, t::Type{T}) where T = elemallowed(DataMD, t) #Allow basic types
elemallowed(::Type{DataRS}, ::Type{DataRS}) = true #Also allow recursive structures

#Generate empty DataRS structure:
(::Type{DataRS{T}})(sweep::PSweep) where T = DataRS{T}(sweep, Array{T}(undef, length(sweep)))


#==Type promotions
===============================================================================#
Base.promote_rule(::Type{T1}, ::Type{T2}) where {T1<:DataRS, T2<:Number} = DataRS


#==Accessor functions
===============================================================================#
Base.eltype(d::DataRS{T}) where T = T
Base.length(d::DataRS) = length(d.elem)


#==Help with construction
===============================================================================#

#Implement "fill(DataRS, ...) do sweepval" syntax:
function Base.fill!(fn::Function, d::DataRS)
	for i in 1:length(d.sweep)
		d.elem[i] = fn(d.sweep.v[i])
	end
	return d
end
Base.fill(fn::Function, ::Type{DataRS{T}}, sweep::PSweep) where T =
	fill!(fn, DataRS(sweep, Array{T}(undef, length(sweep))))
Base.fill(fn::Function, ::Type{DataRS}, sweep::PSweep) = fill(fn, DataRS{DataRS}, sweep)


#==Data generation
===============================================================================#
function _ensuresweepunique(d::DataRS, sweepid::String)
	if sweepid == d.sweep.id
		msg = "Sweep occurs multiple times in DataRS: $sweepid"
		throw(ArgumentError(msg))
	end
end

#Define "parameter".
#(Generates a DataRS object containing the value of a given swept parameter)
#-------------------------------------------------------------------------------

#Deal with non-leaf elements, once the sweep value is found:
function _parameter(d::DataRS{DataRS}, sweepid::String, sweepval::T) where T
	_ensuresweepunique(d, sweepid)
	elem = DataRS[_parameter(d.elem[i], sweepid, sweepval) for i in 1:length(d.sweep)]
	return DataRS(d.sweep, elem)
end

#Deal with leaf elements, once the sweep value is found:
function _parameter(d::DataRS, sweepid::String, sweepval::T) where T
	_ensuresweepunique(d, sweepid)
	elem = T[sweepval for i in 1:length(d.sweep)]
	return DataRS(d.sweep, elem)
end

#Main "parameter" algorithm (non-leaf elements):
function parameter(d::DataRS{DataRS}, sweepid::String)
	if sweepid == d.sweep.id #Sweep found
		elem = DataRS[_parameter(d.elem[i], sweepid, d.sweep.v[i]) for i in 1:length(d.sweep)]
	else
		elem = DataRS[parameter(d.elem[i], sweepid) for i in 1:length(d.sweep)]
	end
	return DataRS(d.sweep, elem)
end
#Main "parameter" algorithm (leaf elements):
function parameter(d::DataRS, sweepid::String)
	T = eltype(d.sweep.v)
	if sweepid == d.sweep.id #Sweep found
		return DataRS(d.sweep, d.sweep.v)
	else
		msg = "Sweep not found in DataRS: $sweepid"
		throw(ArgumentError(msg))
	end
end

#Generate DataRS from DataHR.
#-------------------------------------------------------------------------------
function _buildDataRS(d::DataHR, firstinds::Vector{Int})
	curidx = length(firstinds) + 1
	sweep = d.sweeps[curidx]
	if curidx < length(d.sweeps)
		result = DataRS{DataRS}(sweep)
		for i in 1:length(sweep.v)
			result.elem[i] = _buildDataRS(d, vcat(firstinds, i))
		end
	else #Last index.  Copy data over:
		result = DataRS{eltype(d.elem)}(sweep)
		for i in 1:length(sweep.v)
			result.elem[i] = d.elem[firstinds..., i]
		end
	end
	return result
end

function DataRS(d::DataHR)
	return _buildDataRS(d, Int[])
end


#==User-friendly show functions
===============================================================================#

#Print leaf element:
function printDataRSelem(io::IO, ds::DataRS, idx::Int, indent::String)
	if isassigned(ds.elem, idx)
		println(io, ds.elem[idx])
	else
		println(io, indent, "UNDEFINED")
	end
end
#Print next level of recursive DataRS:
function printDataRSelem(io::IO, ds::DataRS{T}, idx::Int, indent::String) where T<:DataRS
	println(io)
	if isassigned(ds.elem, idx)
		printDataRS(io, ds.elem[idx], indent)
	else
		println(io, indent, "UNDEFINED")
	end
end
#Print DataRS structure:
function printDataRS(io::IO, ds::DataRS, indent::String)
	for i in 1:length(ds.elem)
		print(io, "$indent", ds.sweep.id, "=", ds.sweep.v[i], ": ")
		printDataRSelem(io, ds, i, "$indent  ")
	end
end

function Base.show(io::IO, ds::DataRS)
	print(io, "DataRS[\n")
	printDataRS(io, ds, "  ")
	print(io, "]\n")
end

