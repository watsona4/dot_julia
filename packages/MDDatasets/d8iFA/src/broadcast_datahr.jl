#MDDatasets: Support broadcast of DataHR types
#-------------------------------------------------------------------------------

#TODO: centralize findytypes/promote_type with eltype/result_type functions

#==Type definitions
===============================================================================#

mutable struct SubscriptMap
	outidx::Vector{Int} #List of indices (of output array)
	outlen::Int #Number of indices in output subscript
end
SubscriptMap(inlen::Int, outlen::Int) =
	SubscriptMap(Vector{Int}(undef, inlen), outlen)


#==Error generators
===============================================================================#

function error_mismatchedsweep(basesweep::Vector{PSweep}, subsweep::Vector{PSweep})
	msg = "Mismatched sweeps:\n\nSweep1:\n$basesweep\n\nSweep2:\n$subsweep"
	return ArgumentError(msg)
end

#==Helper functions
===============================================================================#

function ensureuniqueids(s::Vector{PSweep})
	n = length(s)
	for i in 1:n
		for j in (i+1):n
			if s[i] == s[j]
				throw(ArgumentError("Sweep id not unique: \"$(s[i])\""))
			end
		end
	end
end

#Find "base" sweep (most complex data configuration to broadcast up to)
#-------------------------------------------------------------------------------
function basesweep(s1::Vector{PSweep}, s2::Vector{PSweep})
	return length(s1)>length(s2) ? s1 : s2
end
basesweep(s::Vector{PSweep}, d::DataHR) = basesweep(s,d.sweeps)
basesweep(s::Vector{PSweep}, d::DataF1) = s
basesweep(s::Vector{PSweep}, d::Number) = s
basesweep(s::Vector{PSweep}, v::Vector{T}) where T<:Number = s
basesweep(d1::DataHR, d2::DataHR) = basesweep(d1.sweeps,d2.sweeps)
basesweep(d1::DataHR, d2) = basesweep(d1.sweeps,d2)
basesweep(d1, d2::DataHR) = basesweep(d2.sweeps,d2)

#Functions to map array dimensions when broadcasting up a DataHR dataset
#-------------------------------------------------------------------------------
function getmap(basesweep::Vector{PSweep}, subsweep::Vector{PSweep})
	ensureuniqueids(basesweep)
	result = SubscriptMap(length(basesweep), length(subsweep))
	found = zeros(Bool, length(subsweep))
	for i in 1:length(basesweep)
		idx = findfirst((x)->(x.id==basesweep[i].id), subsweep)
		if nothing == idx; idx = 0; end
		result.outidx[i] = idx
		if idx>1
			if basesweep[i].v != subsweep[idx].v
				msg = "Mismatched sweeps:\n$basesweep\n$subsweep"
				throw(error_mismatchedsweep(basesweep, subsweep))
			end
			found[idx] = true
		end
	end
	if !all(found); throw(error_mismatchedsweep(basesweep, subsweep)); end
	return result
end
function remap(_map::SubscriptMap, inds::Vector{Int})
	result = Vector{Int}(_map.outlen)
	for i in 1:length(inds)
		idx = _map.outidx[i]
		if idx > 0; result[idx] = inds[i]; end
	end
	return result
end


#==Broadcasting data up-to a given sweep dimension
===============================================================================#
#WARN: Renamed broadcastMDSweep due to strange dispatch issues as "broadcastMD"
function broadcastMDSweep(s::Vector{PSweep}, d::T) where T<:Number
	result = DataHR{T}(s)
	for i in 1:length(result.elem)
		result.elem[i] = d
	end
	return result
end
function broadcastMDSweep(s::Vector{PSweep}, d::DataF1)
	result = DataHR{DataF1}(s)
	for i in 1:length(result.elem)
		result.elem[i] = d
	end
	return result
end
function broadcastMDSweep(s::Vector{PSweep}, d::DataHR{T}) where T
	if s == d.sweeps; return d; end
	_map = getmap(s, d.sweeps)
	result = DataHR{T}(s)
	for inds in subscripts(result)
		result.elem[inds...] = d.elem[remap(_map, inds)...]
	end
	return result
end


#==Broadcast function call on multi-dimensional data
===============================================================================#
#Broadcast data up to base sweep of two first arguments, then call fn
function _broadcast(::Type{T}, s::Vector{PSweep}, fn::Function, args...; kwargs...) where T
	if length(s) < 1
		return fn(args...; kwargs...)
	end
	bargs = Vector{Any}(undef, length(args)) #Broadcasted version of args
	for i in 1:length(args)
		if typeof(args[i])<:DataMD
			bargs[i] = broadcastMDSweep(s, args[i])
		else
			bargs[i] = args[i]
		end
	end
	bkwargs = Vector{Pair}(undef, length(kwargs)) #Broadcasted version of kwargs
	for (i, kv) in enumerate(kwargs)
		(k,v) = kv
		if typeof(v)<:DataMD
			bkwargs[i] = (k => broadcastMDSweep(s, v))
		else
			bkwargs[i] = kv
		end
	end
	result = DataHR{T}(s) #Create empty result
	for i in 1:length(result.elem)
		curargs = Vector{Any}(undef, length(bargs))
		for j in 1:length(bargs)
			if typeof(bargs[j]) <: DataHR
				curargs[j] = bargs[j].elem[i]
			else
				curargs[j] = bargs[j]
			end
		end
		curkwargs = Vector{Pair}(undef, length(bkwargs))
		for j in 1:length(bkwargs)
			(k,v) = bkwargs[j]
			if typeof(v) <: DataHR
				curkwargs[j] = (k => v.elem[i])
			else
				curkwargs[j] = bkwargs[j]
			end
		end
		result.elem[i] = fn(curargs...; curkwargs...)
	end
	return result
end

#Trap to provide more useful message:
function broadcastMD(ct::CastType, fn::Function, args...; kwargs...)
	msg = "Cast type not supported for call to $fn: $ct"
	throw(ArgumentError(msg))
end

#Find base sweep for a 1-argument broadcastMD
#-------------------------------------------------------------------------------
fnbasesweep(fn::Function, d) = PSweep[]
fnbasesweep(fn::Function, d::DataHR{T}) where T = d.sweeps

#Ensure collection is composed of DataF1 (ex: DataHR{DataF1}):
#Collapses outer-most dimension of DataHR{Number} to a DataHR{DataF1} value, if necessary
#-------------------------------------------------------------------------------
ensure_coll_DataF1(fn::Function, d) = d #Plain data is ok.
ensure_coll_DataF1(fn::Function, d::DataHR) = DataHR{DataF1}(d)

#Broadcast functions capable of operating directly on 1 base type (Number):
#-------------------------------------------------------------------------------
#DataHR{DataF1/Number}
broadcastMD(::CastType1{Number,1}, fn::Function, d::DataHR{T}, args...; kwargs...) where T =
	_broadcast(T, fnbasesweep(fn, d), fn, d, args...; kwargs...)
#Data reducing (DataHR{DataF1/Number})
function broadcastMD(::CastTypeRed1{Number,1}, fn::Function, d::DataHR{T}, args...; kwargs...) where T<:Number
	d = ensure_coll_DataF1(fn, d) #Collapse DataHR{Number}  => DataHR{DataF1}
	_broadcast(T, fnbasesweep(fn, d), fn, d, args...; kwargs...)
end
function broadcastMD(::CastTypeRed1{Number,1}, fn::Function, d::DataHR{DataF1}, args...; kwargs...)
	TR = promote_type(findytypes(d.elem)...) #TODO: Better way?
	_broadcast(TR, fnbasesweep(fn, d), fn, d, args...; kwargs...)
end

#Broadcast functions capable of operating only on a dataF1 value:
#-------------------------------------------------------------------------------
#TODO: These signatures come in conflict with what is needed for DataRS
#DataF1
function broadcastMD(::CastType1{DataF1,1}, fn::Function, d, args...; kwargs...)
	d = ensure_coll_DataF1(fn, d) #Collapse DataHR{Number}  => DataHR{DataF1}
	_broadcast(DataF1, fnbasesweep(fn, d), fn, d, args...; kwargs...)
end
#Expects DataF1 @ arg #2:
function broadcastMD(::CastType1{DataF1,2}, fn::Function, dany1, d, args...; kwargs...)
	d = ensure_coll_DataF1(fn, d) #Collapse DataHR{Number}  => DataHR{DataF1}
	_broadcast(DataF1, fnbasesweep(fn, d), fn, dany1, d, args...; kwargs...)
end
#Data reducing (DataF1)
function broadcastMD(::CastTypeRed1{DataF1,1}, fn::Function, d, args...; kwargs...)
	d = ensure_coll_DataF1(fn, d) #Collapse DataHR{Number}  => DataHR{DataF1}
	TR = promote_type(findytypes(d.elem)...) #TODO: Better way?
	_broadcast(TR, fnbasesweep(fn, d), fn, d, args...; kwargs...)
end


#Find base sweep for a 2-argument broadcast
#-------------------------------------------------------------------------------
function fnbasesweep(fn::Function, d1, d2)
	local s
	try
		s = basesweep(d1,d2)
	catch
		t1 = typeof(d1); t2 = typeof(d2)
		msg = "No signature found for $fn($t1, $t2, ...)"
		throw(ArgumentError(msg))
	end
end

#Ensure collection is composed of DataF1 (ex: DataHR{DataF1}):
#Collapses outer-most dimension of DataHR{Number} to a DataHR{DataF1} value, if necessary
#-------------------------------------------------------------------------------
function ensure_coll_DataF1(fn::Function, d1, d2)
	try
		d1 = ensure_coll_DataF1(fn, d1)
		d2 = ensure_coll_DataF1(fn, d2)
	catch
		t1 = typeof(d1); t2 = typeof(d2)
		msg = "No signature found for $fn($t1, $t2, ...)"
		throw(ArgumentError(msg))
	end
	return tuple(d1, d2)
end

#Broadcast functions capable of operating directly on base types (Number, Number):
#-------------------------------------------------------------------------------
#DataHR{DataF1/Number} & DataHR{DataF1/Number}:
function broadcastMD(::CastType2{Number,1,Number,2}, fn::Function,
	d1::DataHR{T1}, d2::DataHR{T2}, args...; kwargs...) where {T1,T2}
	_broadcast(promote_type(T1,T2), fnbasesweep(fn, d1, d2), fn, d1, d2, args...; kwargs...)
end
#DataHR{DataF1/Number} & DataF1/Number:
function broadcastMD(::CastType2{Number,1,Number,2}, fn::Function,
	d1::DataHR{T1}, d2::T2, args...; kwargs...) where {T1,T2<:DF1_Num}
	_broadcast(promote_type(T1,T2), fnbasesweep(fn, d1, d2), fn, d1, d2, args...; kwargs...)
end
#DataF1/Number & DataHR{DataF1/Number}:
function broadcastMD(::CastType2{Number,1,Number,2}, fn::Function,
	d1::T1, d2::DataHR{T2}, args...; kwargs...) where {T1<:DF1_Num,T2}
	_broadcast(promote_type(T1,T2), fnbasesweep(fn, d1, d2), fn, d1, d2, args...; kwargs...)
end

#Broadcast functions capable of operating only on a dataF1 value:
#-------------------------------------------------------------------------------
#DataF1, DataF1
function broadcastMD(::CastType2{DataF1,1,DataF1,2}, fn::Function, d1, d2, args...; kwargs...)
	(d1, d2) = ensure_coll_DataF1(fn, d1, d2) #Collapse DataHR{Number}  => DataHR{DataF1}
	_broadcast(DataF1, fnbasesweep(fn, d1, d2), fn, d1, d2, args...; kwargs...)
end
#DataF1, DataF1 @ arg 2/3:
function broadcastMD(::CastType2{DataF1,2,DataF1,3}, fn::Function, dany1, d1, d2, args...; kwargs...)
	(d1, d2) = ensure_coll_DataF1(fn, d1, d2) #Collapse DataHR{Number}  => DataHR{DataF1}
	_broadcast(DataF1, fnbasesweep(fn, d1, d2), fn, dany1, d1, d2, args...; kwargs...)
end
#Data reducing (DataF1, DataF1)
function broadcastMD(::CastTypeRed2{DataF1,1,DataF1,2}, fn::Function, d1, d2, args...; kwargs...)
	(d1, d2) = ensure_coll_DataF1(fn, d1, d2) #Collapse DataHR{Number}  => DataHR{DataF1}
	TR = promote_type(findytypes(d1.elem)...,findytypes(d2.elem)...) #TODO: Better way?
	_broadcast(DataF1, fnbasesweep(fn, d1, d2), fn, d1, d2, args...; kwargs...)
end

#More custom broadcastMD functions
#-------------------------------------------------------------------------------
function broadcastMD(::CastType2{DataF1,1,Number,2}, fn::Function, d1, d2, args...; kwargs...)
	d1 = ensure_coll_DataF1(fn, d1) #Collapse DataHR{Number}  => DataHR{DataF1}
	TR = promote_type(findytypes(d1.elem)...,eltype(d2)) #TODO: Better way?
	_broadcast(DataF1, fnbasesweep(fn, d1, d2), fn, d1, d2, args...; kwargs...)
end

#Last Line
