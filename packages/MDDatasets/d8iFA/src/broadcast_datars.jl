#MDDatasets: Support broadcast of DataRS types
#-------------------------------------------------------------------------------


#==result_type: Figure out result type for a function call with given arguments
===============================================================================#
#=NOTES:
 - result_type never returns concrete DataRS{T}.  Only abstract "DataRS".

 - The default return types specified here are not necessarily correct.
   Methods should be overwritten for special functions.
   Sadly: can't currently dispatch on function.  Need to think about this.
=#

result_type(fn::Function, ::Type{T1}, ::Type{T2}) where {T1<:DataRS, T2<:DataRS} = DataRS
result_type(fn::Function, ::Type{T1}, ::Type{T2}) where {T1<:DataRS, T2} = DataRS
result_type(fn::Function, ::Type{T1}, ::Type{T2}) where {T1, T2<:DataRS} = DataRS

#Reducting functions
#-------------------------------------------------------------------------------
result_type(CT::CastTypeRed, fn::Function, ::Type{DataRS{T1}}) where T1<:Number = T1
result_type(CT::CastTypeRed, fn::Function, ::Type{DataRS{T}}) where T = DataRS


#==eltype/valtype: Figure out result type for a function call with given arguments
===============================================================================#

#Element type of an operation with a DataRS (result: DataRS):
Base.eltype(fn::Function, d1::DataRS) = result_type(fn, eltype(d1))

Base.eltype(fn::Function, d1::DataRS, d2::DataRS) = 
	result_type(fn, eltype(d1), eltype(d2))
Base.eltype(fn::Function, d1::DataRS, d2) = 
	result_type(fn, eltype(d1), typeof(d2))
Base.eltype(fn::Function, d1, d2::DataRS) = 
	result_type(fn, typeof(d1), eltype(d2))

#Reducting functions
#-------------------------------------------------------------------------------
#Element type afer reducing fn on Array{Number}:
Base.eltype(CT::CastTypeRed, fn::Function, a::Vector{T}) where T<:Number = result_type(CT, fn, typeof(a))

#Element type afer reducing fn on Array{DataF1}:
function Base.eltype(CT::CastTypeRed, fn::Function, a::Array{DataF1})
	result = Set{DataType}()
	for elem in a
		RT = result_type(CT, fn, typeof(elem))
		push!(result, RT)
	end
	return promote_type(result...)
end

#Element type afer reducing fn on Array{DataRS}:
function Base.eltype(CT::CastTypeRed, fn::Function, a::Vector{DataRS})
	result = Set{DataType}()
	RT = result_type(CT, fn, typeof(a[1]))
	if DataRS == RT; return DataRS; end
	for elem in a
		RT = result_type(CT, fn, typeof(elem))
		push!(result, RT)
	end
	return promote_type(result...)
end


#==Broadcast tools for fn(DataMD) - Can broadcast on 1 argument
===============================================================================#

#Broadcast functions capable of operating directly on 1 base type (Number):
#-------------------------------------------------------------------------------
#fn(DataRS) - core: fn(Number):
function broadcastMD(CT::CastType1{Number,1}, fn::Function, d::DataRS, args...; kwargs...)
	result = DataRS{eltype(fn, d)}(d.sweep)
	for i in 1:length(d.sweep)
		result.elem[i] = broadcastMD(CT, fn, d.elem[i], args...; kwargs...)
	end
	return result
end

#Data reducing fn(DataRS{Number}) - core: fn(Number):
broadcastMD(CT::CastTypeRed1{Number,1}, fn::Function, d::DataRS{T}, args...; kwargs...) where T<:Number =
	fn(d.elem, args...; kwargs...)

#Data reducing fn(DataRS) - core: fn(Number):
function broadcastMD(CT::CastTypeRed1{Number,1}, fn::Function, d::DataRS, args...; kwargs...)
	RT = eltype(CT, fn, d.elem)
	result = DataRS{RT}(d.sweep)
	for i in 1:length(d.sweep)
		result.elem[i] = broadcastMD(CT, fn, d.elem[i], args...; kwargs...)
	end
	return result
end

#Broadcast functions capable of operating only on a dataF1 value:
#-------------------------------------------------------------------------------
#fn(DataRS) - core: fn(DataF1):
function broadcastMD(CT::CastType1{DataF1,1}, fn::Function, d::DataRS{T}, args...; kwargs...) where T
	result = DataRS{T}(d.sweep)
	for i in 1:length(d.sweep)
		result.elem[i] = broadcastMD(CT, fn, d.elem[i], args...; kwargs...)
	end
	return result
end
#fn(???, DataRS) - core: fn(???, DataF1):
function broadcastMD(CT::CastType1{DataF1,2}, fn::Function, dany1, d::DataRS{T}, args...; kwargs...) where T
	result = DataRS{T}(d.sweep)
	for i in 1:length(d.sweep)
		result.elem[i] = broadcastMD(CT, fn, dany1, d.elem[i], args...; kwargs...)
	end
	return result
end

#Data reducing fn(DataRS) - core: fn(Number):
broadcastMD(CT::CastTypeRed1{DataF1,1}, fn::Function, d::DataRS{T}, args...; kwargs...) where T<:Number =
	fn(DataF1(d.sweep.v, d.elem), args...; kwargs...)

#Data reducing fn(DataRS) - core: fn(Number):
function broadcastMD(CT::CastTypeRed1{DataF1,1}, fn::Function, d::DataRS, args...; kwargs...)
	RT = eltype(CT, fn, d.elem)
	result = DataRS{RT}(d.sweep)
	for i in 1:length(d.sweep)
		result.elem[i] = broadcastMD(CT, fn, d.elem[i], args...; kwargs...)
	end
	return result
end

#==Broadcast tools for fn(DataMD, DataMD) - Can broadcast on 2 arguments
===============================================================================#

#Broadcast functions capable of operating directly on base types (Number, Number):
#-------------------------------------------------------------------------------
#fn(DataRS, DataRS) - core: fn(Number, Number):
function broadcastMD(CT::CastType2{Number,1,Number,2}, fn::Function,
	d1::DataRS, d2::DataRS, args...; kwargs...)
	if d1.sweep != d2.sweep
		msg = "Sweeps do not match (not yet supported):"
		throw(ArgumentError(string(msg, "\n", d1.sweep, "\n", d2.sweep)))
	end
	result = DataRS{eltype(fn, d1, d2)}(d1.sweep)
	for i in 1:length(d1.sweep)
		result.elem[i] = broadcastMD(CT, fn, d1.elem[i], d2.elem[i], args...; kwargs...)
	end
	return result
end

#fn(DataRS, DataF1/Number) - core: fn(Number, Number):
function broadcastMD(CT::CastType2{Number,1,Number,2}, fn::Function,
	d1::DataRS, d2::DF1_Num, args...; kwargs...)
	result = DataRS{eltype(fn, d1, d2)}(d1.sweep)
	for i in 1:length(d1.sweep)
		result.elem[i] = broadcastMD(CT, fn, d1.elem[i], d2, args...; kwargs...)
	end
	return result
end

#fn(DataF1/Number, DataRS) - core: fn(Number, Number):
function broadcastMD(CT::CastType2{Number,1,Number,2}, fn::Function,
	d1::DF1_Num, d2::DataRS, args...; kwargs...)
	result = DataRS{eltype(fn, d1, d2)}(d2.sweep)
	for i in 1:length(d2.sweep)
		result.elem[i] = broadcastMD(CT, fn, d1, d2.elem[i], args...; kwargs...)
	end
	return result
end

#Broadcast functions capable of operating on DataF1 values:
#-------------------------------------------------------------------------------
const DF1_DRS = Union{DataF1,DataRS}
#fn(DataRS, DataRS) - core: fn(DataF1, DataF1):
function broadcastMD(CT::CastType2{DataF1,1,DataF1,2}, fn::Function,
	d1::DataRS{T1}, d2::DataRS{T2}, args...; kwargs...) where {T1<:DF1_DRS,T2<:DF1_DRS}
	if d1.sweep != d2.sweep
		msg = "Sweeps do not match (not yet supported):"
		throw(ArgumentError(string(msg, "\n", d1.sweep, "\n", d2.sweep)))
	end
	result = DataRS{eltype(fn, d1, d2)}(d1.sweep)
	for i in 1:length(d1.sweep)
		result.elem[i] = broadcastMD(CT, fn, d1.elem[i], d2.elem[i], args...; kwargs...)
	end
	return result
end
function broadcastMD(CT::CastType2{DataF1,1,DataF1,2}, fn::Function,
	d1::DataRS{T1}, d2::DataRS{T2}, args...; kwargs...) where {T1<:Number,T2<:Number}

	if d1.sweep.id != d2.sweep.id
		msg = "Sweep ids do not match:"
		throw(ArgumentError(string(msg, "\n", d1.sweep, "\n", d2.sweep)))
	end
	return fn(DataF1(d1.sweep.v, d1.elem), DataF1(d2.sweep.v, d2.elem), args...; kwargs...)
end
function broadcastMD(CT::CastType2{DataF1,1,DataF1,2}, fn::Function,
	d1::DataRS{T1}, d2::DataMD, args...; kwargs...) where T1<:Number
	return broadcastMD(CT, fn, DataF1(d1.sweep.v, d1.elem), d2, args...; kwargs...)
end
function broadcastMD(CT::CastType2{DataF1,1,DataF1,2}, fn::Function,
	d1::DataMD, d2::DataRS{T2}, args...; kwargs...) where T2<:Number
	return broadcastMD(CT, fn, d1, DataF1(d2.sweep.v, d2.elem), args...; kwargs...)
end

#fn(DataRS, DataF1) - core: fn(DataF1, DataF1):
function broadcastMD(CT::CastType2{DataF1,1,DataF1,2}, fn::Function,
	d1::DataRS{TRS}, d2::DataF1, args...; kwargs...) where TRS<:DF1_DRS
	result = DataRS{eltype(fn, d1, d2)}(d1.sweep)
	for i in 1:length(d1.sweep)
		result.elem[i] = broadcastMD(CT, fn, d1.elem[i], d2, args...; kwargs...)
	end
	return result
end
#fn(DataF1, DataRS) - core: fn(DataF1, DataF1):
function broadcastMD(CT::CastType2{DataF1,1,DataF1,2}, fn::Function,
	d1::DataF1, d2::DataRS{TRS}, args...; kwargs...) where TRS<:DF1_DRS
	result = DataRS{eltype(fn, d1, d2)}(d2.sweep)
	for i in 1:length(d2.sweep)
		result.elem[i] = broadcastMD(CT, fn, d1, d2.elem[i], args...; kwargs...)
	end
	return result
end
#Last line
