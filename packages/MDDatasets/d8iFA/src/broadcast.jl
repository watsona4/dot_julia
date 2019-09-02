#MDDatasets: Base broadcast support
#-------------------------------------------------------------------------------

#==Nomenclature:
A 1-argument function is one where 1 argument in particular dictates the
dimensonality of the operation.

A 2-argument function is one where 2 arguments dictate the dimensionality of
the operation.
==#

#==Type definitions
===============================================================================#
abstract type CastType end
abstract type CastTypeRed <: CastType end #Identifies a reducing function

#Identifies a function cast with 1 argument of TCAST:
struct CastType1{TCAST, POS} <: CastType; end
#Identifies a reducing function cast with 1 argument of TCAST, returning collection(Number):
struct CastTypeRed1{TCAST, POS} <: CastTypeRed; end
#Identifies a function cast with 2 argument of TCAST1/2:
struct CastType2{TCAST1, POS1, TCAST2, POS2} <: CastType; end
#Identifies a reducing function cast with 2 argument of TCAST1/2, returning collection(Number):
struct CastTypeRed2{TCAST1, POS1, TCAST2, POS2} <: CastTypeRed; end #Reducing function (DataF1->Number)

#Constructors:
CastType(::Type{T}, pos::Int) where T = CastType1{T, pos}()
CastType(::Type{T1}, pos1::Int, ::Type{T2}, pos2::Int) where {T1,T2} =
	CastType2{T1, pos1, T2, pos2}()

CastTypeRed(::Type{T}, pos::Int) where T = CastTypeRed1{T, pos}()
CastTypeRed(::Type{T1}, pos1::Int, ::Type{T2}, pos2::Int) where {T1,T2} =
	CastTypeRed2{T1, pos1, T2, pos2}()


#==Constants
===============================================================================#
#Cast on function capable of operating directly on base types (Number):
const CAST_BASEOP1 = CastType(Number, 1)
const CAST_BASEOPRED1 = CastTypeRed(Number, 1)

#Cast on function capable of operating directly on base types (Number, Number):
const CAST_BASEOP2 = CastType(Number, 1, Number, 2)

#Cast on function capable of operating only on DataF1:
const CAST_MD1 = CastType(DataF1, 1)
const CAST_MDRED1 = CastTypeRed(DataF1, 1)

#Cast on function capable of operating only on DataF1:
const CAST_MD2 = CastType(DataF1, 1, DataF1, 2)
const CAST_MDRED2 = CastTypeRed(DataF1, 1, DataF1, 2)


#==result_type: Figure out result type for a function call with given arguments
===============================================================================#
#=NOTES:
 - Advantage: Helps with readability.
 - Disadvantage: Might add extra level on call stack for simple operations (hope inlines).

 - result_type never returns concrete DataF1{TX,TY}.  Only abstract "DataF1".

 - (Future) special functions might behave differently.
   ie: The default return types specified here are not necessarily correct.
   Methods should be overwritten for special functions.
   Sadly: can't currently dispatch on function.  Need to think about this.
=#
#-------------------------------------------------------------------------------

result_type(fn::Function, ::Type{T1}) where T1 = T1 #In=out... wrong with functions like sin(Int)=>Float64
result_type(fn::Function, ::Type{T1}) where T1<:DataF1 = DataF1


result_type(fn::Function, ::Type{T1}, ::Type{T2}) where {T1<:Number, T2<:Number} = promote_type(T1, T2)
result_type(fn::Function, ::Type{T1}, ::Type{T2}) where {T1<:DataF1, T2<:DataF1} = DataF1
result_type(fn::Function, ::Type{T1}, ::Type{T2}) where {T1<:DataF1, T2<:Number} = DataF1
result_type(fn::Function, ::Type{T1}, ::Type{T2}) where {T1<:Number, T2<:DataF1} = DataF1

result_type(CT::CastTypeRed, fn::Function, ::Type{DataF1{TX,TY}}) where {TX,TY} = TY


#==eltype/valtype: Figure out result type for a function call with given arguments
===============================================================================#

#y-element type of an operation with a DataF1 (result: DataF1):
Base.valtype(fn::Function, d1::Number, d2::DataF1) =
	result_type(fn, typeof(d1), eltype(d2.y))
Base.valtype(fn::Function, d1::DataF1, d2::Number) =
	result_type(fn, eltype(d1.y), typeof(d2))
Base.valtype(fn::Function, d1::DataF1, d2::DataF1) =
	result_type(fn, eltype(d1.y), eltype(d2.y))


#=="apply" function
===============================================================================#

#"apply" between a DataF1 & basic scalar (Number)
function apply(fn::Function, d1::DataF1, d2::Number, args...; kwargs...)
	RT = valtype(fn, d1, d2)
	y = RT[fn(yi, d2, args...; kwargs...) for yi in d1.y]
	return DataF1(d1.x, y)
end
function apply(fn::Function, d1::Number, d2::DataF1, args...; kwargs...)
	RT = valtype(fn, d1, d2)
	y = RT[fn(d1, yi, args...; kwargs...) for yi in d2.y]
	return DataF1(d2.x, y)
end

#Generic broadcastMD functions (avoids name collisions):
#NOTE: "core" means most elemental version of the function
#-------------------------------------------------------------------------------
#fn(DataF1) - core: fn(Number)
broadcastMD(::CastType1{Number,1}, fn::Function, d::DataF1, args...; kwargs...) =
	DataF1(d.x, fn(d.y, args...; kwargs...))

#fn(DataF1) - core: fn(DataF1)
broadcastMD(::CastType1{DataF1,1}, fn::Function, d::DataF1, args...; kwargs...) =
	fn(d, args...; kwargs...)

#Reducing fn(DataF1) - core: fn(Number)
broadcastMD(::CastTypeRed1{Number,1}, fn::Function, d::DataF1, args...; kwargs...) =
	fn(d.y, args...; kwargs...)

#fn(Number, Number) - core: fn(Number, Number)
broadcastMD(CT::CastType2{Number,1,Number,2}, fn::Function, d1::Number, d2::Number, args...; kwargs...) =
	fn(d1, d2, args...; kwargs...)

#fn(DataF1, DataF1) - core: fn(Number, Number)
broadcastMD(CT::CastType2{Number,1,Number,2}, fn::Function, d1::DataF1, d2::DataF1, args...; kwargs...) =
	apply(fn, d1, d2, args...; kwargs...)

#fn(DataF1, Number) - core: fn(Number, Number)
broadcastMD(CT::CastType2{Number,1,Number,2}, fn::Function, d1::DataF1, d2::Number, args...; kwargs...) =
	apply(fn, d1, d2, args...; kwargs...)

#fn(Number, DataF1) - core: fn(Number, Number)
broadcastMD(CT::CastType2{Number,1,Number,2}, fn::Function, d1::Number, d2::DataF1, args...; kwargs...) =
	apply(fn, d1, d2, args...; kwargs...)

#fn(DataF1, DataF1) - core: fn(DataF1, DataF1)
broadcastMD(CT::CastType2{DataF1,1,DataF1,2}, fn::Function, d1::DataF1, d2::DataF1, args...; kwargs...) =
	fn(d1, d2, args...; kwargs...)

#Reducing fn(DataF1) - core: fn(DataF1)
broadcastMD(::CastTypeRed1{DataF1,1}, fn::Function, d::DataF1, args...; kwargs...) =
	fn(d, args...; kwargs...)

#Last line
