#math_coordinates.jl: 
#-------------------------------------------------------------------------------


#==Types
===============================================================================#

#Tag data as being part of a given coordinate system:
struct CoordSystem{ID}; end
const DeviceCoord = CoordSystem{:dev}
const AxisCoord = CoordSystem{:axis}
const NormCoord = CoordSystem{:norm} #Normalized (ex: relative to axis-delimited viewport)
const DataCoord = CoordSystem{:data}

#Never actually used:
#... but could simplify names of mapping functions/mitigate incorrect use.
struct TypedCoord{CT<:CoordSystem}
	v::DReal
end
coord(s::Symbol, v::DReal) = TypedCoord{CoordSystem{s}}(v)

#Annotation coordinates can match data or be normalized to plot bounds (0 -> 1):
#NOTE: not used
const AnnotationCoord = Union{TypedCoord{NormCoord}, TypedCoord{DataCoord}}

#Dispatchable scale:
abstract type AxisScale end #Note: "Scale" too generic a name

struct LinScale{T} <: AxisScale
	tgtmajor::DReal #Targeted number of major grid lines
	tgtminor::Int   #Targeted number of minor grid lines
	(t::Type{LinScale{_T}})(a1, a2) where _T = error("$t not supported")
	(::Type{LinScale{1}})(a1, a2) = new{1}(a1, a2) #Default linear
	(::Type{LinScale{:dB10}})(a1, a2) = new{:dB10}(a1, a2)
	(::Type{LinScale{:dB20}})(a1, a2) = new{:dB20}(a1, a2)
end
LinScale(t=1; tgtmajor=3.5, tgtminor=4) = LinScale{t}(tgtmajor, tgtminor)

struct LogScale{T} <: AxisScale
	#TODO: Configure how many major/minor lines are desired?
	(t::Type{LogScale{_T}})() where _T = error("$t not supported")
	(::Type{LogScale{:e}})() = new{:e}()
	(::Type{LogScale{2}})() = new{2}()
	(::Type{LogScale{10}})() = new{10}()
end
LogScale(t) = LogScale{t}()

function AxisScale(t::Symbol; kwargs...)
	if :ln == t; return LogScale(:e); end
	if :log2 == t; return LogScale(2); end
	if :log10 == t; return LogScale(10); end
	if :log == t; return LogScale(10); end #Alias
	if :lin == t; return LinScale(1; kwargs...); end
	return LinScale(t; kwargs...)
end
AxisScale() = AxisScale(:lin)


#Nonlinear transform type definitions
#-------------------------------------------------------------------------------
abstract type NLTransform{NDIMS} end #Nonlinear transform

#InputXfrm: Maps raw input data to axis coordinates:

#InputXfrm1DSpec: Generates specialized (efficient) code:
struct InputXfrm1DSpec{T} <: NLTransform{1}
end
InputXfrm1DSpec(::LinScale{1}) = InputXfrm1DSpec{:lin}()
InputXfrm1DSpec(::LinScale{:dB10}) = InputXfrm1DSpec{:dB10}()
InputXfrm1DSpec(::LinScale{:dB20}) = InputXfrm1DSpec{:dB20}()
InputXfrm1DSpec(::LogScale{:e}) = InputXfrm1DSpec{:ln}()
InputXfrm1DSpec(::LogScale{2}) = InputXfrm1DSpec{:log2}()
InputXfrm1DSpec(::LogScale{10}) = InputXfrm1DSpec{:log10}()

struct InputXfrm1D <: NLTransform{1} #Generates non-specialized code
	spec::InputXfrm1DSpec
end
InputXfrm1D(s::AxisScale) = InputXfrm1D(InputXfrm1DSpec(s))
struct InputXfrm2D <: NLTransform{2} #Generates non-specialized code
	x::InputXfrm1DSpec #x-transform
	y::InputXfrm1DSpec #y-transform
end
InputXfrm2D(x::InputXfrm1D, y::InputXfrm1D) = InputXfrm2D(x.spec, y.spec)
InputXfrm2D(xs::AxisScale, ys::AxisScale) = InputXfrm2D(InputXfrm1DSpec(xs), InputXfrm1DSpec(ys))

#Offsettable 2D position:
#TODO: Should reloffset exist as is?
#      Alt: v.x/y is *either* "read" or "relative" (use relx::Bool, rely::Bool)
mutable struct Pos2DOffset
	v::Point2D #Position ("Read"able coordinates) - set NaN to use offsets only
	reloffset::Vector2D #Relative offset (Normalized to [0,1] graph bounds)
	offset::Vector2D #Absolute offset (device units)
end


#==Mapping/interpolation functions
===============================================================================#
#Map input data to axis coordinates:
map2axis(::Type{T}, ::InputXfrm1DSpec{:lin}) where T<:Number = (x::T)->DReal(x)
map2axis(::Type{T}, ::InputXfrm1DSpec{:dB10}) where T<:Number = (x::T)->(5*log10(DReal(abs2(x))))
map2axis(::Type{T}, ::InputXfrm1DSpec{:dB20}) where T<:Number = (x::T)->(10*log10(DReal(abs2(x))))
map2axis(::Type{T}, ::InputXfrm1DSpec{:ln}) where T<:Number =
	(x::T)->(x<0 ? DNaN : log(DReal(x)))
map2axis(::Type{T}, ::InputXfrm1DSpec{:log2}) where T<:Number =
	(x::T)->(x<0 ? DNaN : log2(DReal(x)))
map2axis(::Type{T}, ::InputXfrm1DSpec{:log10}) where T<:Number =
	(x::T)->(x<0 ? DNaN : log10(DReal(x)))
#TODO: find a way to show negative values for log10?

#Map axis coord --> user-readable coord (Typically reverse of map2axis):
axis2read(::Type{T}, ::InputXfrm1DSpec) where T<:Number = (x::T)->DReal(x) #NOTE: lin/dB values remain as-is - for readability
axis2read(::Type{T}, ::InputXfrm1DSpec{:ln}) where T<:Number = (x::T)->(exp(x))
axis2read(::Type{T}, ::InputXfrm1DSpec{:log2}) where T<:Number = (x::T)->(2.0^x)
axis2read(::Type{T}, ::InputXfrm1DSpec{:log10}) where T<:Number = (x::T)->(10.0^x)

axis2read(v::T, s::InputXfrm1DSpec) where T<:Number = axis2read(T,s)(v) #One-off conversion

#Map user-readable coord --> axis coord (Typically same as map2axis):
read2axis(::Type{T}, ixf::InputXfrm1DSpec) where T<:Number = map2axis(T, ixf)
#Exception: "Readable" coordinates match axis coordinates when in dB:
read2axis(::Type{T}, ::InputXfrm1DSpec{:dB10}) where T<:Number = (x::DReal)->x
read2axis(::Type{T}, ::InputXfrm1DSpec{:dB20}) where T<:Number = (x::DReal)->x

read2axis(v::T, s::InputXfrm1DSpec) where T<:Number = read2axis(T,s)(v) #One-off conversion


#Map Point2D:
#-------------------------------------------------------------------------------
#TODO: define one-off conversion for map2axis to simplify following?:
map2axis(pt::Point2D, xixf::InputXfrm1DSpec, yixf::InputXfrm1DSpec) =
	Point2D(map2axis(DReal, xixf)(pt.x), map2axis(DReal, yixf)(pt.y))
map2axis(pt::Point2D, ixf::InputXfrm2D) = map2axis(pt, ixf.x, ixf.y)
axis2read(pt::Point2D, xixf::InputXfrm1DSpec, yixf::InputXfrm1DSpec) =
	Point2D(axis2read(pt.x, xixf), axis2read(pt.y, yixf))
axis2read(pt::Point2D, ixf::InputXfrm2D) = axis2read(pt, ixf.x, ixf.y)
read2axis(pt::Point2D, xixf::InputXfrm1DSpec, yixf::InputXfrm1DSpec) =
	Point2D(read2axis(pt.x, xixf), read2axis(pt.y, yixf))
read2axis(pt::Point2D, ixf::InputXfrm2D) = read2axis(pt, ixf.x, ixf.y)


#Map entire data vector:
#-------------------------------------------------------------------------------
function map2axis(d::Vector{T}, xf::InputXfrm1DSpec) where T<:Number
	#Apparently, passing functions as arguments is not efficient in Julia.
	#-->Specializing on InputXfrm1DSpec, hoping to improve efficiency on dmap:
	dmap = map2axis(T, xf)

	result = Array{DReal}(undef, length(d))
	for i in 1:length(d)
		result[i] = dmap(d[i])
	end
	return result
end
map2axis(d::Vector{T}, ::InputXfrm1DSpec{:lin}) where T<:Number = d #Optimization: Linear scale does not need re-scaling


#Extents mapping functions, depending on axis type:
#-------------------------------------------------------------------------------
#Shortcut - hardwire type used in extents:
_extread2axis(t::InputXfrm1DSpec) = read2axis(DReal, t)
_extaxis2read(t::InputXfrm1DSpec) = axis2read(DReal, t)

function read2axis(ext::PExtents1D, xf::InputXfrm1D)
	emap = _extread2axis(xf.spec)
	return PExtents1D(emap(ext.min), emap(ext.max))
end
function read2axis(ext::PExtents2D, xf::InputXfrm2D)
	xmap = _extread2axis(xf.x)
	ymap = _extread2axis(xf.y)
	return PExtents2D(
		xmap(ext.xmin), xmap(ext.xmax),
		ymap(ext.ymin), ymap(ext.ymax)
	)
end

function axis2read(ext::PExtents1D, xf::InputXfrm1D)
	emap = _extaxis2read(xf.spec)
	return PExtents1D(emap(ext.min), emap(ext.max))
end
function axis2read(ext::PExtents2D, xf::InputXfrm2D)
	xmap = _extaxis2read(xf.x)
	ymap = _extaxis2read(xf.y)
	return PExtents2D(
		xmap(ext.xmin), xmap(ext.xmax),
		ymap(ext.ymin), ymap(ext.ymax)
	)
end

#Pos2DOffset mapping functions:
#-------------------------------------------------------------------------------
function map2dev(pos::Pos2DOffset, xf::Transform2D, ixf::InputXfrm2D, graphbb::BoundingBox)
	pt = read2axis(pos.v, ixf)
	pt = map2dev(xf, pt)
	x = pt.x; y = pt.y
	if isnan(x); x = graphbb.xmin; end
	if isnan(y); y = graphbb.ymax; end
	x += pos.reloffset.x * width(graphbb) + pos.offset.x
	y -= pos.reloffset.y * height(graphbb) + pos.offset.y
	return Point2D(x, y)
end

#Last line
