#**************************************************************************************
# Physics_Model.jl
# ================ part of the GeoEfficiency.jl package.
#
# here is the place where all physical elements is being modeled and created as computer objects.
#
#**************************************************************************************

#------------------ consts - globals - imports -------------------

using Compat
using Compat: @info, @warn, @error
import Base: show, isless


#-------------------------- Point ----------------------------------

"""

    Point(Height::Real, Rho::Real)

construct and return a `Point` source.
The `Point` can be used as either a source by itself or an `anchor point` of a higher dimension source.

*  `Height` : point height relative to the detector surface.
*  `Rho` : point off-axis relative to the detector axis of symmetry.

!!! note
    Each detector type give different interpretation to the `height` as follow:-
    *  for `CylDetector` the point source `height` is consider to be measured 
       from the detector `face surface`. 
    *  for `BoreDetector` the point source `height` is consider to be measured 
       from the `detector middle`, +ve value are above the detector center while -ve are below. 
    *  for `WellDetector` the point source `height` is considered to be measured 
       from the detector `hole surface`. 

"""
struct Point
	Height::Float64
	Rho::Float64
	Point(Height::Float64, Rho::Float64) = new(Height, Rho)
end #type
Point(Height::Real, Rho::Real) = Point(float(Height), float(Rho))

"""

	Point(Height::Real)

construct and return an `axial point`.

**see also:** [`Point(Height::Real, Rho::Real)`](@ref).

"""
Point(Height::Real) = Point(Height, 0.0)

"""

	Point()

construct and return a `point`. prompt to input information via the `console`. 

**see also:** [`Point(Height::Real, Rho::Real)`](@ref).

"""
function Point()
	printstyled("\n II- The Radioactive Source Anchor Point:-\n", color=:yellow)
	Height = getfloat("\n\t > Height (cm) = ")
	Rho = getfloat("\n\t > Off-axis (cm) = ")
	Point(Height, Rho)
end #function

"""
	Point(xHeight::Real, aPnt::Point)

construct and return a `point` that has the same off-axis distance as `aPnt` but of new 
height `xHeight`. 

**see also:** [`Point(Height::Real, Rho::Real)`](@ref)

"""
Point(xHeight::Real, aPnt::Point) = Point(xHeight, aPnt.Rho)

"""
	Point(aPnt::Point, xRho::Real)

construct and return a `point` that has the same height as `aPnt` but of new 
off-axis distance `Rho`. 

**see also:** [`Point(Height::Real, Rho::Real)`](@ref).

"""
Point(aPnt::Point, xRho::Real) = Point(aPnt.Height, xRho)

id(aPnt::Point) = "Point[Height=$(aPnt.Height), Rho=$(aPnt.Rho)]"
show(pnt::Point) = print(id(pnt))


#--------------source---------------------------------------------

"""

	source(anchorPnt::Point = Point())

return a tuple that describe the source (`anchorPnt`, `SrcRadius`, `SrcLength`) according to 
the input from the `console`.

*  `anchorPnt` : the source anchoring point. if it is missing the user is prompt 
   to input it via the `console`.
*  `SrcRadius` : source radius.
*  `SrcLength` : source length.

!!! warning 
	if source type set to point source, both `SrcRadius` and `SrcLength` are set to zero. 
    for more information **see also:** [`typeofSrc()`](@ref) and [`typeofSrc(x::Int)`](@ref).
"""
function source(anchorPnt::Point = Point())::Tuple{Point, Float64, Float64}
    
	if setSrcToPoint()
		@info("""srcType is set to ``srcPoint``,
		**see** `setSrcToPoint` for more information.""")
		return (anchorPnt, 0.0, 0.0)
	end #if

	SrcRadius = getfloat("\n\t > Source Radius (cm) = ", 0.0)
    if 0.0 != SrcRadius
        SrcLength = getfloat("\n\t > Source Length (cm) = ", 0.0)
		@error("currently only axial non-point sources are allowed")
		@warn("the off-axis will be set to `Zero`")
		anchorPnt = Point(anchorPnt, 0.0)

	else
        SrcLength = 0.0
		@warn("`SrcLength` is set to `zero`")

	end #if
    return (anchorPnt, SrcRadius, SrcLength)
end #function


#---------------- Detector ------------------------------------

"abstract super-supertype of all detectors types"
abstract type RadiationDetector end

"""

	Detector

abstract supertype of all detectors types of cylidericalish shapes.
also can be used to construct any leaf type.

"""
abstract type Detector <: RadiationDetector end
show(io::IO, detector::RadiationDetector) = print(id(detector))
isless(detector1::RadiationDetector, detector2::RadiationDetector) = isless(volume(detector1), volume(detector2))


##-------------- CylDetector -----------------------------------

"""

	CylDetector(CryRadius::Real, CryLength::Real)

construct and return a `cylindrical` detector of the given crystal dimensions:-

*  `CryRadius` : the detector crystal radius.
*  `CryLength` : the detector crystal length.

!!! warning
    both `CryRadius` and `CryLength` should be `positive`, while `CryLength` can also be set to **`zero`**.

"""
struct CylDetector <: Detector
	CryRadius::Float64    	#Real
    CryLength::Float64		#Real

	function CylDetector(CryRadius::Float64, CryLength::Float64)
		@validateDetector	CryRadius > 0.0		"Crystal Radius: expect +ve number, get '$(CryRadius)'"
		@validateDetector	CryLength >= 0.0	"Crystal Length: expect +ve number or zero, get '$(CryLength)'"
		new(CryRadius, CryLength)
	end #function

end #type
CylDetector(CryRadius::Real, CryLength::Real) = CylDetector(float(CryRadius), float(CryLength))

"""

    CylDetector(CryRadius::Real)

construct and return a `cylindrical` (really `disk`) detector with crystal length equal to **`zero`**.

**see also:** [`CylDetector(CryRadius::Real, CryLength::Real)`](@ref).

"""
CylDetector(CryRadius::Real) = CylDetector(CryRadius, 0.0)


"""

    CylDetector()

construct and return a `cylindrical` detector according to the input from the `console`.

**see also:** [`CylDetector(CryRadius::Real, CryLength::Real)`](@ref).

"""
function CylDetector()
	printstyled(" I- The Cylindrical Detector physical Dimensions:-\n", color=:yellow)
	CryRadius = getfloat("\n\t > Crystal Radius (cm) = ", 0.0)
	CryLength = getfloat("\n\t > Crystal Length (cm) = ", 0.0)
	CylDetector(CryRadius, CryLength)
end #function

id(detector::CylDetector) = "CylDetector[CryRadius=$(detector.CryRadius), CryLength=$(detector.CryLength)]"
volume(detector::CylDetector) = pi * detector.CryRadius^2 * detector.CryLength 


##------------- BoreDetector -------------------------------------

"""

	BoreDetector(CryRadius::Real, CryLength::Real, HoleRadius::Real)

construct and return a `bore-hole` detector of the given crystal dimensions:-

*  `CryRadius` : the detector crystal radius.
*  `CryLength` : the detector crystal length.
*  `HoleRadius` : the detector hole radius.

!!! warning
    `CryRadius` and `CryLength`, `HoleRadius` should be `positive` numbers, also 
    `CryRadius` should be greater than `HoleRadius`.

"""
struct BoreDetector <: Detector
	CryRadius::Float64    	#Real
    CryLength::Float64    	#Real
	HoleRadius::Float64    	#Real

	function BoreDetector(CryRadius::Float64, CryLength::Float64, HoleRadius::Float64)
		@validateDetector	CryRadius > 0.0		"Crystal Radius: expect +ve number, get '$(CryRadius)'"
		@validateDetector	CryLength > 0.0		"Crystal Length: expect +ve number, get '$(CryLength)'"
		@validateDetector	CryRadius > HoleRadius > 0.0	"Hole Radius: expect +ve number Less than 'Crystal Radius=$(CryRadius)', get $(HoleRadius)."
		new(CryRadius, CryLength, HoleRadius)
	end #function

end #type
BoreDetector(CryRadius::Real, CryLength::Real, HoleRadius::Real) = BoreDetector(float(CryRadius), float(CryLength), float(HoleRadius))

"""

	BoreDetector()

construct and return a `bore-hole` detector according to the input from the `console`.

**see also:** [`BoreDetector(CryRadius::Real, CryLength::Real, HoleRadius::Real)`](@ref).

"""
function BoreDetector()
	printstyled(" I- The Bore Hole Detector physical Dimensions:-\n", color=:yellow)
	CryRadius  = getfloat("\n\t > Crystal Radius (cm) = ", 0.0)
	CryLength  = getfloat("\n\t > Crystal Length (cm) = ", 0.0)
	HoleRadius = getfloat("\n\t > Hole Radius (cm) = ", 0.0, CryRadius)
	BoreDetector(CryRadius, CryLength, HoleRadius)
end #function

id(detector::BoreDetector) = "BoreDetector[CryRadius=$(detector.CryRadius), CryLength=$(detector.CryLength), HoleRadius=$(detector.HoleRadius)]"
volume(detector::BoreDetector) = pi * (detector.CryRadius^2 - detector.HoleRadius^2) * detector.CryLength 


##----------------------- WellDetector ------------------------------------------

"""

	WellDetector(CryRadius::Real, CryLength::Real, HoleRadius::Real, HoleDepth::Real)

construct and return a `Well-Type` detector of the given crystal dimensions:-

*  `CryRadius` : the detector crystal radius.
*  `CryLength` : the detector crystal length.
*  `HoleRadius` : the detector hole radius.
*  `HoleDepth` : the detector hole length.

!!! warning
    all arguments should be `positive` numbers, also 
    `CryRadius` should be greater than `HoleRadius` and 
    `CryLength` should be greater than  `HoleDepth`. 

"""
struct WellDetector <: Detector
	CryRadius::Float64
    CryLength::Float64
	HoleRadius::Float64
	HoleDepth::Float64

	function WellDetector(CryRadius::Float64, CryLength::Float64, HoleRadius::Float64, HoleDepth::Float64)
		@validateDetector	CryRadius > 0.0				"Crystal Radius: expect +ve number, get '$(CryRadius)'"
		@validateDetector	CryLength > 0.0				"Crystal Length: expect +ve number, get '$(CryLength)'"
		@validateDetector	CryRadius > HoleRadius > 0.0	"Hole Radius: expect +ve number Less than 'Crystal Radius=$(CryRadius)', get '(HoleRadius)'"
		@validateDetector	CryLength > HoleDepth > 0.0	   	"Hole Depth: expect +ve number Less than 'Crystal Length=$(CryLength)', get '$(HoleDepth)'"
		new(CryRadius, CryLength, HoleRadius, HoleDepth)
	end #if

end #type
WellDetector(CryRadius::Real, CryLength::Real, HoleRadius::Real, HoleDepth::Real) = WellDetector(float(CryRadius), float(CryLength), float(HoleRadius), float(HoleDepth))

"""

	WellDetector()

construct and return a Well-Type detector according to the input from the `console`.

**see also:** [`WellDetector(CryRadius::Real, CryLength::Real, HoleRadius::Real, HoleDepth::Real)`](@ref).

"""
function WellDetector()
	printstyled(" I- The Well-Type Detector physical Dimensions:-\n", color=:yellow)
	CryRadius  = getfloat("\n\t > Crystal Radius (cm) = ", 0.0)
	CryLength  = getfloat("\n\t > Crystal Length (cm) = ", 0.0)
	HoleRadius = getfloat("\n\t > Hole Radius (cm) = ", 0.0, CryRadius)
	HoleDepth  = getfloat("\n\t > Hole Radius (cm) = ", 0.0, CryLength)
	WellDetector(CryRadius, CryLength, HoleRadius, HoleDepth)
end #function

id(detector::WellDetector) = "WellDetector[CryRadius=$(detector.CryRadius), CryLength=$(detector.CryLength), HoleRadius=$(detector.HoleRadius), HoleDepth=$(detector.HoleDepth)]"
volume(detector::WellDetector) = pi * (detector.CryRadius^2 * detector.CryLength - detector.HoleRadius ^2 * detector.HoleDepth)


#---------------------------- Detector -------------------------------------

"""

	Detector()

construct and return an object of the `Detector` leaf types 
(`CylDetector`, `BoreDetector` or `WellDetector`) according to the input from the console.

!!! note 
    all required information is acquired from the `console` and would warn user on invalid data.

"""
function Detector()
	printstyled( "\n I- The detector physical Dimensions :-\n", color=:yellow)
	CryRadius  = getfloat("\n\t > Crystal Radius (cm) = ", 0.0)
	CryLength  = getfloat("\n\t > Crystal Length (cm) = ", 0.0)
	HoleRadius = getfloat("\n(zero for cylindrical detectors) > Hole Radius (cm) = ", 0.0, nextfloat(CryRadius))
	if   0.0 == HoleRadius
		return CylDetector(CryRadius, CryLength)

	else
		HoleDepth = getfloat("\n(zero for Bore-Hole detectors) > Hole Depth (cm) = ", 0.0, CryLength )
		return 0.0 == HoleDepth ?
				BoreDetector(CryRadius, CryLength, HoleRadius) :
				WellDetector(CryRadius, CryLength, HoleRadius, HoleDepth)
	end #if
end #function

"""

	Detector(CryRadius::Real)

same as [`CylDetector(CryRadius::Real)`](@ref).

"""
Detector(CryRadius::Real) = CylDetector(CryRadius)

"""

	Detector(CryRadius::Real, CryLength::Real)

same as [`CylDetector(CryRadius::Real, CryLength::Real)`](@ref).

"""
Detector(CryRadius::Real, CryLength::Real) = CylDetector(CryRadius, CryLength)

"""

	Detector(CryRadius::Real, CryLength::Real, HoleRadius::Real)

same as [`BoreDetector(CryRadius::Real, CryLength::Real, HoleRadius::Real)`](@ref) except
when `HoleRadius` = `0.0` it acts as  [`CylDetector(CryRadius::Real, CryLength::Real)`](@ref).

"""
Detector(CryRadius::Real, CryLength::Real, HoleRadius::Real) = 0.0 == HoleRadius ?
				                                        CylDetector(CryRadius, CryLength) :
				                                        BoreDetector(CryRadius, CryLength, HoleRadius)

"""

	Detector(CryRadius::Real, CryLength::Real, HoleRadius::Real, HoleDepth::Real)

construct and return `well-type`, `bore-hole` or `cylindrical` detector according to the arguments. 
it inspect the arguments and call the appropriate leaf type constructor.

!!! note
    if the value(s) of the last argument(s) is\\are `zero`, it acts as a missing argument(s).
		
**see also:** [`CylDetector`](@ref), [`BoreDetector`](@ref), [`WellDetector`](@ref).

"""
Detector(CryRadius::Real, CryLength::Real, HoleRadius::Real, HoleDepth::Real) = 0.0 == HoleDepth ?
				                                        Detector(CryRadius, CryLength, HoleRadius) :
				                                        WellDetector(CryRadius, CryLength, HoleRadius, HoleDepth)

"""

	Detector(detector::Detector)

return the inputted detector.

"""
Detector(detector::Detector) = detector

"""

	Detector(detectors::Vector{<: Detector})

convert the array `detectors` of any of the leaf `Detector` types 
to an array of type `Detector`.

"""
Detector(detectors::Vector{<:Detector}) = Detector[detectors...]
