#GracePlot: Lightweight units
#-------------------------------------------------------------------------------

#==TODO:
use proper units/quantity module, as described in:
https://github.com/ma-laforge/testcases/blob/master/units_test/units_test.jl
==#


#==Constants
===============================================================================#
const INCH_IN_METERS = .0254
const INCH_IN_POINTS = 72


#==Type definitions
===============================================================================#

abstract type AbstractQuantity end
val(x::AbstractQuantity) = x.v

abstract type AbstractLength <: AbstractQuantity end

#Typographic (DTP) "point":
struct TPoint <: AbstractLength
	v::Number
end

struct Inch <: AbstractLength
	v::Number
end

struct Meter <: AbstractLength
	v::Number
end


#==Conversion functions:
===============================================================================#
Base.convert(::Type{Inch}, x::Meter) = Inch(val(x)*(1/INCH_IN_METERS))
Base.convert(::Type{Inch}, x::TPoint) = Inch(val(x)*(1/INCH_IN_POINTS))
Base.convert(::Type{Meter}, x::Inch) = Meter(val(x)*INCH_IN_METERS)
Base.convert(::Type{TPoint}, x::Inch) = TPoint(val(x)*INCH_IN_POINTS)

#Indirect conversions:
Base.convert(::Type{Meter}, x::TPoint) = convert(Meter, convert(Inch, x))
Base.convert(::Type{TPoint}, x::Meter) = convert(TPoint, convert(Inch, x))

TPoint(x::TPoint) = x
Meter(x::Meter) = x
Inch(x::Inch) = x
TPoint(x::AbstractLength) = convert(TPoint, x)
Meter(x::AbstractLength) = convert(Meter, x)
Inch(x::AbstractLength) = convert(Inch, x)

#end
