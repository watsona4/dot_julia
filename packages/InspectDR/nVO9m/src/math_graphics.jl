#math_graphics.jl: 
#-------------------------------------------------------------------------------


#==Aliases
===============================================================================#
#Real data type used for display functionnality (low-level):
const DReal = Float64


#==Constants
===============================================================================#
const DInf = convert(DReal, Inf)
const DNaN = convert(DReal, NaN)

const COLOR_TRANSPARENT = ARGB32(0, 0, 0, 0)

const COLOR_BLACK = RGB24(0, 0, 0)
const COLOR_WHITE = RGB24(1, 1, 1)

const COLOR_RED = RGB24(1, 0, 0)
const COLOR_GREEN = RGB24(0, 1, 0)
const COLOR_BLUE = RGB24(0, 0, 1)


#==Data structures.
===============================================================================#
#TODO: Use library version?
abstract type Point end #So we can use as a function
struct Point2D <: Point
	x::DReal
	y::DReal
end

abstract type DirectionalVector end
struct Vector2D <: DirectionalVector
	x::DReal
	y::DReal
end
Vector2D(p::Point2D) = Vector2D(p.x, p.y)
Point2D(p::Vector2D) = Point2D(p.x, p.y)

#Plot extents along one dimension:
struct PExtents1D
	min::DReal
	max::DReal
end
PExtents1D(;min::Real=DNaN, max::Real=DNaN) = PExtents1D(min, max)

#Could use BoundingBox, but cannot control type (and is technically not a BB).
#TODO: PExtents2D from PExtents1D?
struct PExtents2D
	xmin::DReal
	xmax::DReal
	ymin::DReal
	ymax::DReal
end
PExtents2D(;xmin::Real=DNaN, xmax::Real=DNaN, ymin::Real=DNaN, ymax::Real=DNaN) =
	PExtents2D(xmin, xmax, ymin, ymax)
PExtents2D(xext::PExtents1D, yext::PExtents1D) =
	PExtents2D(xext.min, xext.max, yext.min, yext.max)

#Transform used for Canvas2D/CanvasF1 (only scale/offset - no rotation).
#xd = (xs + x0) * xu
#yd = (ys + y0) * yu
#where: xu/yu: user coordinates & xd/yd: device coordinates
#NOTE: Format used instead of xs*xu + x0 for improved numeric stability?
#TODO: Does struct cause copy on function calls instead of using pointers??
struct Transform2D
	xs::DReal
	x0::DReal
	ys::DReal
	y0::DReal
end

struct LineStyle
	style::Symbol
	width::Float64 #Device units (~pixels)
	color::Colorant
end


#==Constructor-like functions
===============================================================================#
#=Inputs
 -ext: Visible plot extents
 -inputb: Bounding box of display area.
NOTE:
 -Assumes device y-coordinate increases as we descend on the screen.
=#
function Transform2D(ext::PExtents2D, inputb::BoundingBox)
	xs = (inputb.xmax-inputb.xmin) / (ext.xmax-ext.xmin)
	ys = -(inputb.ymax-inputb.ymin) / (ext.ymax-ext.ymin)
	x0 = + inputb.xmin/xs - ext.xmin
	y0 = + inputb.ymax/ys - ext.ymin

	return Transform2D(xs, x0, ys, y0)
end


#==Accessors
===============================================================================#
xvalues(ext::PExtents2D) = PExtents1D(ext.xmin, ext.xmax)
yvalues(ext::PExtents2D) = PExtents1D(ext.ymin, ext.ymax)


#==Basic operations
===============================================================================#
#Compute vector norm:
function vecnorm(v::Vector2D)
	return sqrt(v.x*v.x+v.y*v.y)
end

#Simple scaling - no commutativity:
Base.:*(s::DReal, pt::Point2D) = Point2D(s*pt.x, s*pt.y)
Base.:*(s::Real, pt::Point2D) = DReal(s)*pt
Base.:+(p1::Point2D, p2::Point2D) = Point2D(p1.x+p2.x, p1.y+p2.y)
Base.:-(p1::Point2D, p2::Point2D) = Point2D(p1.x-p2.x, p1.y-p2.y)

Base.:*(s::DReal, v::Vector2D) = Vector2D(s*v.x, s*v.y)
Base.:*(s::Real, v::Vector2D) = DReal(s)*v
Base.:+(v1::Vector2D, v2::Vector2D) = Vector2D(v1.x+v2.x, v1.y+v2.y)

Base.:+(p::Point2D, v::Vector2D) = Point2D(p.x+v.x, p.y+v.y)
Base.:-(p::Point2D, v::Vector2D) = Point2D(p.x-v.x, p.y-v.y)
Base.:+(v::Vector2D, p::Point2D) = p+v

function union(e1::PExtents1D, e2::PExtents1D)
	umin(v1, v2) = isnan(v1) ? v2 : min(v1, v2)
	umax(v1, v2) = isnan(v1) ? v2 : max(v1, v2)
	return PExtents1D(
		umin(e1.min, e2.min),
		umax(e1.max, e2.max),
	)
end
function union(elist::Vector{PExtents1D})
	result = PExtents1D(DNaN, DNaN)
	for ext in elist
		result = union(result, ext)
	end
	return result
end

function union(e1::PExtents2D, e2::PExtents2D)
	umin(v1, v2) = isnan(v1) ? v2 : min(v1, v2)
	umax(v1, v2) = isnan(v1) ? v2 : max(v1, v2)
	return PExtents2D(
		umin(e1.xmin, e2.xmin),
		umax(e1.xmax, e2.xmax),
		umin(e1.ymin, e2.ymin),
		umax(e1.ymax, e2.ymax),
	)
end
function union(elist::Vector{PExtents2D})
	result = PExtents2D(DNaN, DNaN, DNaN, DNaN)
	for ext in elist
		result = union(result, ext)
	end
	return result
end

#Overwrite with new extents, if defined
#-------------------------------------------------------------------------------
function Base.merge(base::PExtents1D, new::PExtents1D)
	baseifnan(bv, nv) = isnan(nv) ? bv : nv
	emin = baseifnan(base.min, new.min)
	emax = baseifnan(base.max, new.max)
	return PExtents1D(emin, emax)
end

function Base.merge(base::PExtents2D, new::PExtents2D)
	baseifnan(bv, nv) = isnan(nv) ? bv : nv
	xmin = baseifnan(base.xmin, new.xmin)
	xmax = baseifnan(base.xmax, new.xmax)
	ymin = baseifnan(base.ymin, new.ymin)
	ymax = baseifnan(base.ymax, new.ymax)
	return PExtents2D(xmin, xmax, ymin, ymax)
end

Base.isfinite(ext::PExtents1D) = isfinite(ext.min) && isfinite(ext.max)

Base.isfinite(ext::PExtents2D) =
	isfinite(ext.xmin) && isfinite(ext.xmax) &&
	isfinite(ext.ymin) && isfinite(ext.ymax)


#==Mapping/interpolation functions
===============================================================================#

#Map axis -> device coordinates:
function map2dev(xf::Transform2D, pt::Point2D)
	x = (pt.x + xf.x0)*xf.xs
	y = (pt.y + xf.y0)*xf.ys
	return Point2D(x, y)
end
#Map device -> axis coordinates (reverse mapping):
function map2axis(xf::Transform2D, pt::Point2D)
	x = pt.x/xf.xs - xf.x0
	y = pt.y/xf.ys - xf.y0
	return Point2D(x, y)
end

#Map vectors between axis -> device coordinate systems:
function map2dev(xf::Transform2D, pt::Vector2D)
	x = pt.x*xf.xs
	y = pt.y*xf.ys
	return Vector2D(x, y)
end
#Map vectors between device -> axis coordinate systems (reverse mapping):
function map2axis(xf::Transform2D, pt::Vector2D)
	x = pt.x/xf.xs
	y = pt.y/xf.ys
	return Vector2D(x, y)
end

#Interpolate between two points.
#-------------------------------------------------------------------------------
function interpolate(p1::Point2D, p2::Point2D, x::DReal)
	m = (p2.y-p1.y) / (p2.x-p1.x)
	return m*(x-p1.x)+p1.y
end

#Last line
