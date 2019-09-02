#MDDatasets DataHR defninitions
#-------------------------------------------------------------------------------

#==Main types
===============================================================================#

#Hyper-rectangle -representation of data:
#-------------------------------------------------------------------------------
mutable struct DataHR{T} <: DataMD
	sweeps::Vector{PSweep}
	elem::Array{T}

	function DataHR{T}(sweeps::Vector{PSweep}, elem::Array{T}) where {T}
		if !elemallowed(DataMD, eltype(elem))
			msg = "Can only create DataHR{T} for T ∈ {DataF1, DataFloat, DataInt, DataComplex}"
			throw(ArgumentError(msg))
		elseif ndims(DataHR, sweeps) != ndims(elem)
			throw(ArgumentError("Number of sweeps must match dimensionality of elem"))
		end
		return new(sweeps, elem)
	end
end

#Shorthand (because default (non-parameterized) constructor was overwritten):
DataHR(sweeps::Vector{PSweep}, a::Array{T}) where T = DataHR{T}(sweeps, a)

#Construct DataHR from Vector{PSweep}:
(::Type{DataHR{T}})(sweeps::Vector{PSweep}) where T = DataHR{T}(sweeps, Array{T}(undef, size(DataHR, sweeps)...))

#Construct DataHR{DataF1} from DataHR{Number}
#Collapse inner-most sweep (last dimension), by default:
#TODO: use convert(...) instead?
function (::Type{DataHR{DataF1}})(d::DataHR{T}) where T<:Number
	sweeps = d.sweeps[1:end-1]
	x = d.sweeps[end].v

	#Collapsed last sweep:
	if length(sweeps) < 1
		y = d.elem
		return DataF1(x, reshape(y, length(y)))
	end

	#Reduced DataHR structure:
	result = DataHR{DataF1}(sweeps) #Construct empty results
	_sub = collect(subscripts(result))
	for inds in _sub
		y = d.elem[inds...,:]
		result.elem[inds...] = DataF1(x, reshape(y, length(y)))
	end
	return result
end

#Relay function, so people can blindly convert to DataHR{DataF1} using any DataHR:
(::Type{DataHR{DataF1}})(d::DataHR{DataF1}) = d


#==Type promotions
===============================================================================#
Base.promote_rule(::Type{T1}, ::Type{T2}) where {T1<:DataHR, T2<:Number} = DataHR


#==Accessor functions
===============================================================================#
#Compute the size of a DataHR array from a Vector{PSweep}:
function Base.size(::Type{DataHR}, sweeps::Vector{PSweep})
	dims = Int[]
	for s in sweeps
		push!(dims, length(s.v))
	end
	if 0 == length(dims) #Without sweeps, you can still have a single subset
		push!(dims, 1)
	end
	return tuple(dims...)
end

#Returns the dimension corresponding to the given string:
function dimension(::Type{DataHR}, sweeps::Vector{PSweep}, id::String)
	dim = findfirst((s)->(id==s.id), sweeps)
	ensure(dim!=nothing, ArgumentError("Sweep not found: $id."))
	return dim
end
dimension(d::DataHR, id::String) = dimension(DataHR, d.sweeps, id)

#Returns an element subscripts iterator for a DataHR corresponding to Vector{PSweep}.
subscripts(::Type{DataHR}, sweeps::Vector{PSweep}) =
	subscripts(size(DataHR, sweeps))
subscripts(d::DataHR) = subscripts(d.elem)

#Dimensionality of DataHR array:
Base.ndims(::Type{DataHR}, sweeps::Vector{PSweep}) = max(1, length(sweeps))
Base.ndims(d::DataHR) = ndims(DataHR, d.sweeps)

#Obtain sweep info
#-------------------------------------------------------------------------------
sweeps(d::DataHR) = d.sweeps
sweep(d::DataHR, dim::Int) = d.sweeps[dim].v
sweep(d::DataHR, dim::String) = d.sweeps[dim].v

#Returns parameter sweep coordinates corresponding to given subscript:
function coordinates(d::DataHR, subscr::Tuple=0)
	result = []
	if length(d.sweeps) > 0
		for i in 1:length(subscr)
			push!(result, sweep(d, i)[subscr[i]])
		end
	end
	return result
end


#==Help with construction
===============================================================================#

#Implement "fill(DataHR, ...) do sweepval" syntax:
function Base.fill!(fn::Function, d::DataHR)
	for inds in subscripts(d)
		d.elem[inds...] = fn(coordinates(d, inds)...)
	end
	return d
end
Base.fill(fn::Function, ::Type{DataHR{T}}, sweeps::Vector{PSweep}) where T =
	fill!(fn, DataHR{T}(sweeps))
Base.fill(fn::Function, ::Type{DataHR}, sweeps::Vector{PSweep}) = fill(fn, DataHR{DataF1}, sweeps)
Base.fill(fn::Function, ::Type{DataHR{T}}, sweep::PSweep) where T = fill(fn, DataHR{DataF1}, PSweep[sweep])


#==Data generation
===============================================================================#
#Generate a DataHR object containing the value of a given swept parameter:
function parameter(::Type{DataHR}, sweeps::Vector{PSweep}, sweepno::Int)
	sw = sweeps[sweepno].v #Sweep of interest
	T = eltype(sw)
	result = DataHR{T}(sweeps)
	for inds in subscripts(result)
		result.elem[inds...] = sw[inds[sweepno]]
	end
	return result
end
parameter(::Type{DataHR}, sweeps::Vector{PSweep}, id::String) =
	parameter(DataHR, sweeps, dimension(DataHR, sweeps, id))
parameter(d::DataHR, id::String) = parameter(DataHR, d.sweeps, id)


#==Dataset reductions
===============================================================================#

#Like getindex(A, inds...), but with DataHR:
#TODO: Support array "view"s instead of copying with "getindex" for efficiency??
function getsubarrayind(d::DataHR{T}, inds...) where T
	sweeps = PSweep[]
	idx = 1
	for rng in inds
		sw = d.sweeps[idx]

		#Only provide a sweep if user selects a range of more than one element:
		addsweep = Colon == typeof(rng) || length(rng)>1
		if addsweep
			push!(sweeps, PSweep(sw.id, sw.v[rng]))
		end
		idx +=1
	end
	return DataHR{T}(sweeps, reshape(getindex(d.elem, inds...), size(DataHR, sweeps)))
end

#getindex(DataHR, inds...), using key/value pairs:
function getsubarraykw(d::DataHR{T}; kwargs...) where T
	sweeps = PSweep[]
	indlist = Vector{Int}[]
	for sweep in d.sweeps
		keepsweep = true
		arg = getkwarg(kwargs, Symbol(sweep.id))
		if arg != nothing
			inds = indices(sweep, arg)
			push!(indlist, inds)
			if length(inds) > 1
				keepsweep = false
				push!(sweeps, PSweep(sweep.id, sweep.v[inds...]))
			end
		else #Keep sweep untouched:
			push!(indlist, 1:length(sweep.v))
			push!(sweeps, sweep)
		end
	end
	return DataHR{T}(sweeps, reshape(getindex(d.elem, indlist...), size(DataHR, sweeps)))
end

#TODO: Support array "view"s instead of copying with "getindex" for efficiency??
#NOTE: Used to be called "sub", which was replaced by "view".
function getsubarray(d::DataHR{T}, args...; kwargs...) where T
	if length(kwargs) > 0
		return getsubarraykw(d, args...; kwargs...)
	else
		return getsubarrayind(d, args...)
	end
end


#==User-friendly show functions
===============================================================================#
#Also changes string():
Base.print(io::IO, ::Type{DataHR{DataF1}}) = print(io, "DataHR{DataF1}")
Base.print(io::IO, ::Type{DataHR{DataFloat}}) = print(io, "DataHR{DataFloat}")
Base.print(io::IO, ::Type{DataHR{DataInt}}) = print(io, "DataHR{DataInt}")
Base.print(io::IO, ::Type{DataHR{DataComplex}}) = print(io, "DataHR{DataComplex}")

function Base.show(io::IO, ds::DataHR)
	szstr = string(size(ds.elem))
	typestr = string(typeof(ds))
	print(io, "$typestr$szstr[\n")
	for inds in subscripts(ds)
		if isassigned(ds.elem, inds...)
			subset = ds.elem[inds...]
			print(io, " $inds: "); show(io, subset); println(io)
		else
			println(io, " $inds: UNDEFINED")
		end
	end
	print(io, "]\n")
end

function Base.show(io::IO, ds::DataHR{T}) where T<:Number
	szstr = string(size(ds.elem))
	typestr = string(typeof(ds))
	print(io, "$typestr$szstr:\n")
	print(io, ds.elem)
end

#Last line
