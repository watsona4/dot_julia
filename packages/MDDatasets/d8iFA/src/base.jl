#MDDatasets base types & core functions
#-------------------------------------------------------------------------------


#==High-level types
===============================================================================#
abstract type DataMD end #Multi-dimensional data
abstract type LeafDS <: DataMD end #Leaf dataset


#==Helper types (TODO: move to somewhere else?)
===============================================================================#

struct MDCUST; end #Custom type used for defining special functions with same name.

#For type stability.  Identifies result as having event count in x-axis
const Event = DS{:event}()

#Explicitly tells multi-dispatch engine a value is meant to be an index:
struct Index
	v::Int
end
Index(idx::AbstractFloat) = Index(round(Int,idx)) #Convenient
value(x::Index) = x.v

#Parameter sweep
mutable struct PSweep{T}
	id::String
	v::Vector{T}
#TODO: ensure increasing order?
end

#TODO: Deprecate DataScalar?? - and LeafDS?
#struct DataScalar{T<:Number} <: LeafDS
#	v::T
#end


#==Leaf data elements
===============================================================================#

#DataF1, Function of 1 variable, y(x): optimized for processing on y-data
#(All y-data points are stored contiguously)
mutable struct DataF1{TX<:Number, TY<:Number} <: LeafDS
	x::Vector{TX}
	y::Vector{TY}
#==TODO: find a way to validate lengths:
	function DataF1{TX<:Number, TY<:Number}(x::Vector{TX}, y::Vector{TY})
		ensure(length(x)==length(y), "Invalid DataF1: x & y lengths do not match")
		return new(x,y)
	end
==#
end
#DataF1{TX<:Number, TY<:Number}(::Type{TX}, ::Type{TY}) = DataF1(TX[], TY[]) #Empty dataset

#Create a function of 1 argument from x-values & function of 1 argument:
function DataF1(x::Vector{TX}, y::Function) where TX<:Number
	ytype = typeof(y(x[1]))
	DataF1(x, ytype[y(elem) for elem in x])
end

function DataF1(x::AbstractRange, y::Function)
	ensureincreasingx(x)
	return DataF1(collect(x), y)
end

#Build a DataF1 object from a x-value range (make y=x):
function DataF1(x::AbstractRange)
	ensureincreasingx(x)
	return DataF1(collect(x), collect(x))
end



#==Type aliases
===============================================================================#
#Shorthands:
const DF1_Num = Union{DataF1,Number}
#const MD_Num = Union{DataMD,Number}

#Alternative to DF1_Num?:
#const MDDataElem = Union{DataF1,DataFloat,DataInt,DataComplex}


#==Type promotions
===============================================================================#
Base.promote_rule(::Type{T1}, ::Type{T2}) where {T1<:DataF1, T2<:Number} = DataF1
Base.promote_rule(::Type{DataF1{TX1,TY1}},::Type{DataF1{TX2,TY2}}) where {TX1,TX2,TY1,TY2} =
	DataF1{promote_type(TX1,TX2),promote_type(TY1,TY2)}

#A way to ignore void types in promote operation:
promote_type_nonvoid(T::Type) = T
promote_type_nonvoid(::Type{Nothing}, ::Type{Nothing}) = Nothing
promote_type_nonvoid(T1::Type, ::Type{Nothing}) = T1
promote_type_nonvoid(::Type{Nothing}, T2::Type) = T2
promote_type_nonvoid(T1::Type, T2::Type) = promote_type(T1,T2)
promote_type_nonvoid(T1::Type, args...) =
	promote_type_nonvoid(T1, promote_type_nonvoid(args...))


#==Supported data types
===============================================================================#
#Identifies whether a type is allowed as an element of a DataMD container
#(ex: DataHR, DataRS):
#==IMPORTANT:
   -Want to support ONLY base data types & leaf types (T<:LeafDS)
	-Want to support leaf types like DataF1 in GENERIC fashion
    (support DataF1[] ONLY - not concrete versions of DataF1{X,Y}[] ==#
elemallowed(::Type{DataMD}, ::Type{T}) where T = false #By default
elemallowed(::Type{DataMD}, ::Type{DataFloat}) = true
elemallowed(::Type{DataMD}, ::Type{DataInt}) = true
elemallowed(::Type{DataMD}, ::Type{DataComplex}) = true
elemallowed(::Type{DataMD}, ::Type{DataF1}) = true
#==TODO:
   -Is this a good idea?
   -Would using DataScalar wrapper & <: LeafDS be better?==#


#==Useful assertions/validations
===============================================================================#

#Make sure two datasets have the same x-coordinates:
function ensuresamex(d1::DataF1, d2::DataF1)
	ensure(d1.x==d2.x,
		ArgumentError("Operation currently only supported for the same x-data."))
end

#WARNING: relatively expensive
function ensureincreasingx(d::DataF1)
	ensure(isincreasing(d.x),
		ArgumentError("DataF1.x must be in increasing order."))
end

function ensureincreasingx(x::AbstractRange)
	ensure(isincreasing(x),
		ArgumentError("Data must be ordered with increasing x"))
end

function ensuremultipoint(x::Limits1D)
	ensure(x.min < x.max,
		ArgumentError("Limits1D: min must be smaller than max"))
end

function ensurenotinverted(x::Limits1D)
	ensure(x.min <= x.max,
		ArgumentError("Limits1D: max cannot be smaller than min"))
end


#Validate data lengths:
function validatelengths(d::DataF1)
	ensure(length(d.x)==length(d.y),
		ArgumentError("Invalid DataF1: x & y lengths do not match."))
end

#Perform simple checks to validate data integrity
function validate(d::DataF1)
	validatelengths(d)
	ensureincreasingx(d)
end


#==Helper functions
===============================================================================#
#Substitute void values with default:
substvoid(::Nothing, dflt) = dflt
substvoid(v, dflt) = v


#==Basic PSweep functionality (traits)
===============================================================================#
Base.values(sweep::PSweep) = sweep.v
Base.length(sweep::PSweep) = length(sweep.v)

Base.names(list::Vector{PSweep}) = [s.id for s in list]

#Return a list of indicies corresponding to desired sweep values:
function indices(sweep::PSweep, vlist)
	result = Int[]
	for v in vlist
		push!(result, findclosestindex(sweep.v, v))
	end
	return result
end


#==Basic DataF1 functionality
===============================================================================#
Base.copy(d::DataF1) = DataF1(d.x, copy(d.y))

function Base.length(d::DataF1)
	validatelengths(d) #Should be sufficiently inexpensive
	return length(d.x)
end

#Obtain a Point2D structure from a DataF1 dataset, at a given index.
Point2D(d::DataF1, i::Int) = Point2D(d.x[i], d.y[i])

#Obtain a list of y-element types in an array of DataF1
function findytypes(a::Array{DataF1})
	result = Set{DataType}()
	for elem in a
		push!(result, eltype(elem.y))
	end
	return [elem for elem in result]
end


#==Interpolations
===============================================================================#

#Interpolate value of a DataF1 dataset for a given x:
#NOTE:
#    -Uses linear interpolation
#    -Assumes value is zero when out of bounds
#    -TODO: binary search
function value(d::DataF1{TX, TY}; x::Number=0) where {TX<:Number, TY<:Number}
	validate(d) #Expensive, but might avoid headaches
	nd = length(d) #Somewhat expensive
	RT = promote_type(TX, TY) #For type stability
	y = zero(RT) #Initialize

	pos = 0
	for i in 1:nd
		if x <= d.x[i]
			pos = i
			break
		end
	end
	#Here: pos=0, or x<=d.x[pos]

	if pos > 1
		y = interpolate(Point2D(d, pos-1), Point2D(d, pos), x=x)
	elseif pos > 0 && x==d.x[1]
		y = convert(RT, d.y[1])
	end
	return y
end

#==Apply fn(d1,d2); where {d1,d2} ∈ DataF1 have independent (but sorted) x-values
===============================================================================#

function applydisjoint(fn::Function, d1::DataF1{TX,TY1}, d2::DataF1{TX,TY2}) where {TX<:Number, TY1<:Number, TY2<:Number}
	ensure(false, ArgumentError("Currently no support for disjoint datasets"))
end

#Apply a function of two scalars to two DataF1 objects:
#NOTE:
#   -Uses linear interpolation
#   -Do not use "map", because this is more complex than one-to-one mapping
#   -Assumes ordered x-values
function apply(fn::Function, d1::DataF1{TX,TY1}, d2::DataF1{TX,TY2}) where {TX<:Number, TY1<:Number, TY2<:Number}
	validate(d1); validate(d2); #Expensive, but might avoid headaches
	zero1 = zero(TY1); zero2 = zero(TY2)
	npts = length(d1)+length(d2)+1 #Allocate for worse case
	x = zeros(TX, npts)
	y = zeros(promote_type(TY1,TY2),npts)
	_x1 = d1.x[1]; _x2 = d2.x[1] #First x-values of d1 & d2
	x1_ = d1.x[end]; x2_ = d2.x[end] #Last x-values of d1 & d2

	if _x1 > x2_ || _x2 > x1_
		return applydisjoint(fn, d1, d2)
	end

	i = 1; i1 = 1; i2 = 1
	#NOTE: i ≜ index into result (x[]).  Low risk of being out of range.
	_x12 = max(_x1, _x2) #First intersecting point
	x[1] = min(_x1, _x2) #First point

	while x[i] < _x2 #Only d1 has values (assume d2 is 0)
		y[i] = fn(d1.y[i1], zero2)
		i += 1; i1 += 1 #x[i] < _x2 and set not disjoint: safe to increment i1
		x[i] = d1.x[i1]
	end
	while x[i] < _x1 #Only d2 has values (assume d1 is 0)
		y[i] = fn(zero1, d2.y[i2])
		i += 1; i2 += 1 #x[i] < _x1 and set not disjoint: safe to increment i2
		x[i] = d2.x[i2]
	end
	x[i] = _x12
	x12_ = min(x1_, x2_) #Last intersecting point
	p1 = p1next = Point2D(d1, i1)
	p2 = p2next = Point2D(d2, i2)
	if i1 > 1; p1 = Point2D(d1, i1-1); end
	if i2 > 1; p2 = Point2D(d2, i2-1); end
	while x[i] < x12_ #Intersecting section of x
		local y1, y2
		if p1next.x == x[i]
			y1 = p1next.y
			i1 += 1 #x[i] < x12_: safe to increment i1
			p1 = p1next; p1next = Point2D(d1, i1)
		else
			y1 = interpolate(p1, p1next, x=x[i])
		end
		if p2next.x == x[i]
			y2 = p2next.y
			i2 += 1 #x[i] < x12_: safe to increment i2
			p2 = p2next; p2next = Point2D(d2, i2)
		else
			y2 = interpolate(p2, p2next, x=x[i])
		end
		y[i] = fn(y1, y2)
		i+=1
		x[i] = min(p1next.x, p2next.x)
	end
	#End of intersecting section:
		y1 = interpolate(p1, p1next, x=x[i])
		y2 = interpolate(p2, p2next, x=x[i])
		y[i] = fn(y1, y2)
	while x[i] < x1_ #Only d1 has values left (assume d2 is 0)
		i += 1
		x[i] = d1.x[i1]
		y[i] = fn(d1.y[i1], zero2)
		i1 += 1
	end
	while x[i] < x2_ #Only d2 has values left (assume d1 is 0)
		i += 1
		x[i] = d2.x[i2]
		y[i] = fn(zero1, d2.y[i2])
		i2 += 1
	end
	npts = i

	return DataF1(resize!(x, npts), resize!(y, npts))
end

#Last line
