#**************************************************************************************
# Calculations.jl
# =============== part of the GeoEfficiency.jl package.
#
# this file collects all the functions which are responsible for 
# the calculations of the Geometrical Efficiency.
#
#**************************************************************************************

#------------------ consts - globals - imports -------------------

using Compat
using Compat: @error, @__MODULE__

# set the global minimum relative and absolute precession of the Geometrical Efficiency Calculations
isconst(@__MODULE__, :relativeError) ||  const relativeError = 1.0E-4	
isconst(@__MODULE__, :absoluteError) ||  const absoluteError = eps(1.0)
isconst(@__MODULE__, :integrate )    ||  const integrate     = begin using QuadGK; QuadGK.quadgk; end


#----------------------- GeoEff_Pnt -------------------------------

"""# UnExported

	GeoEff_Pnt(detector::CylDetector, aPnt::Point)::Float64

return the `geometrical efficiency` for the point source `aPnt` located on front
of the cylindrical detector `detector` face.

## Throw
*  an `NotImplementedError` if the point is out of the cylindrical detector `detector` face.
*  an `InValidGeometry` if the point location is invalide.


!!! note
    this is the base function that all other functions call directly or indirectly
    to calculate `geometrical efficiency` of the cylindrical-ish detector family.

"""
function GeoEff_Pnt(detector::CylDetector, aPnt::Point)::Float64
	aPnt.Rho > detector.CryRadius 	&& 	@notImplementedError("Point off-axis, out of the detector face")
	detector.CryRadius > aPnt.Rho 	&& 	aPnt.Height < 0.0 	&&	@inValidGeometry("The point source location can not be inside the detector")

	function MaxPhi(theta::Float64 )::Float64
		side = aPnt.Height * sin(theta)
		return clamp((aPnt.Rho^2 + side^2 - detector.CryRadius^2 )/ side / aPnt.Rho /2.0, -1.0, 1.0) |> acos
	end # function

	func(theta::Float64)::Float64 = MaxPhi(theta) * sin(theta)

	if 0.0 == aPnt.Rho				# axial Point
		strt = 0.0
		fine = atan(detector.CryRadius , aPnt.Height)
		return integrate(sin, strt, fine, rtol=relativeError, atol=absoluteError)[1]

	else							# non-axial Point
		strt = 0.0
		transition = atan(detector.CryRadius - aPnt.Rho, aPnt.Height)
		fine = atan(detector.CryRadius + aPnt.Rho, aPnt.Height)
		if transition >= 0.0

		 	return integrate(sin, strt, transition, rtol=relativeError, atol=absoluteError)[1] +
                      			integrate(func, transition, fine, rtol=relativeError, atol=absoluteError)[1] / pi

		else
			# This case is not implemented yet
			# TBD: (Top + Side) efficiencies
		end #if

	end #if
end #function


#------------------------ GeoEff_Disk ----------------------------------

"""# UnExported

	GeoEff_Disk(detector::CylDetector, SurfacePnt::Point, SrcRadius::Real)::Float64

return the `geometrical efficiency` for a `disk` source. The `disk` center is the `SurfacePnt` and 
its radius is `SrcRadius` on front of the cylindrical detector `detector` face.

produce a warning if the disk is out of the cylindrical detector face.

"""
function GeoEff_Disk(detector::CylDetector, SurfacePnt::Point, SrcRadius::Real)::Float64
	detector.CryRadius > SurfacePnt.Rho + SrcRadius || @error(
	"off the detector face sources is not supported yet SrcRadius = $(SrcRadius), CryRadius = $(detector.CryRadius ), Rho = $(SurfacePnt.Rho)")
	
	integrand(xRho) = xRho * GeoEff_Pnt(detector, Point(SurfacePnt, xRho))
	return  integrate(integrand, 0.0, SrcRadius, rtol=relativeError, atol=absoluteError)[1] / SrcRadius^2

end #function


#-------------------------- geoEff -----------------------------------

"""

	geoEff(detector::CylDetector, aSurfacePnt::Point, SrcRadius::Real = 0.0, SrcLength::Real = 0.0)::Float64

**please refer to [`geoEff(::Detector, ::Point, ::Real, ::Real)`](@ref geoEff) for more information.**

!!! warning
    `aSurfacePnt` : point `height` is considered to be measured from the detector surface.

"""
function geoEff(detector::CylDetector, aSurfacePnt::Point, SrcRadius::Real = 0.0, SrcLength::Real = 0.0)::Float64
	detector.CryRadius < SrcRadius + aSurfacePnt.Rho   &&	@error(
		"Source Radius: Expected less than 'detector Radius=$(detector.CryRadius)', get $SrcRadius.")
	
	pnt::Point = deepcopy(aSurfacePnt)
		
	if 0.0 == SrcRadius                         #Point source
	
		detector.CryRadius > pnt.Rho || @error(
			"geoEffPoint off-axis: Expected less than 'detector Radius=$(detector.CryRadius)', get $(pnt.Rho).")
        return GeoEff_Pnt(detector, pnt)/2.0            	

	elseif 0.0 == SrcLength						#Disk source
	
        return GeoEff_Disk(detector, pnt, SrcRadius)

	else										# Cylindrical source

        integrand(xH::Float64) = GeoEff_Disk(detector, Point(xH, pnt.Rho), SrcRadius)
		return integrate(integrand , aSurfacePnt.Height, aSurfacePnt.Height + SrcLength, 
						rtol=relativeError, atol=absoluteError)[1] / SrcLength

	end #if
end #function


"""

	geoEff(detector::BoreDetector, aCenterPnt::Point, SrcRadius::Real = 0.0, SrcLength::Real = 0.0)::Float64

**please refer to [`geoEff(::Detector, ::Point, ::Real, ::Real)`](@ref geoEff) for more information.**

!!! warning
    `aCenterPNT` : point `height` is consider to be measured from the detector middle, +ve value are above the detector center while -ve are below.

"""
function geoEff(detector::BoreDetector, aCenterPnt::Point, SrcRadius::Real = 0.0, SrcLength::Real = 0.0)::Float64

	HeightWup = aCenterPnt.Height - detector.CryLength/2.0
	HeightWdown = aCenterPnt.Height + detector.CryLength/2.0
	if HeightWdown < 0.0
		if HeightWup + SrcLength < 0.0 		#invert the source.
			return geoEff(detector, Point(aCenterPnt.Height - detector.CryLength, aCenterPnt.Rho), SrcRadius, SrcLength)

		else # the source span the detector and emerges from both sides, split the source into two sources.
			#res = (1 - 2 * geoEff(detin, Point(0.0), SrcRadius, SrcLength))* detector.CryLength /SrcLength
			return geoEff(detector, Point(0.0), SrcRadius, -aCenterPnt.Height ) * (-aCenterPnt.Height /SrcLength) +
			       geoEff(detector, Point(0.0), SrcRadius, SrcLength + aCenterPnt.Height ) * (1.0 + aCenterPnt.Height /SrcLength)

		end
	end

	pntWup::Point = deepcopy(aCenterPnt);
	aCenterPnt = Point(abs(HeightWup), aCenterPnt);  #0.0 == SrcRadius && Point(pntWup, 0.0)

	pntWdown::Point = deepcopy(aCenterPnt);
	pntWdown = Point(abs(HeightWdown), pntWdown); #0.0 == SrcRadius && Point(pntWdown, 0.0)

	detin::CylDetector = CylDetector(detector.HoleRadius)
	detout::CylDetector = CylDetector(detector.CryRadius)

	if HeightWup >= 0.0						# the source as a whole out of detector
		res = geoEff(detout, pntWup, SrcRadius, SrcLength) - geoEff(detin, pntWdown, SrcRadius, SrcLength)

	elseif HeightWup + SrcLength < 0.0 		# the source as a whole in the detector
		res = 1 - geoEff(detin, Point(abs(HeightWup + SrcLength), pntWup), SrcRadius, SrcLength)
		res -= geoEff(detin, pntWdown, SrcRadius, SrcLength)

	else # elseif SrcLength > 0.0
		res = (1.0 - geoEff(detin, Point(0.0), SrcRadius, -HeightWup))* -HeightWup/SrcLength
		res += geoEff(detout, Point(0.0), SrcRadius, HeightWup + SrcLength) * (1.0 + HeightWup/SrcLength)

	#=else
		return 1.0 - geoEff(detin, Point(-Height, pnt), SrcRadius)[1]
	else
		res = 1 - integrate(xH -> GeoEff_Disk(detin, Point(xH, pnt), SrcRadius), 0.0, -pnt.Height, rtol=relativeError, atol=absoluteError)[1]
		res = res + integrate(xH -> GeoEff_Disk(detout, Point(xH, pntWup), SrcRadius), 0.0, pntWup.Height , rtol=relativeError, atol=absoluteError)[1]
			=#
	end #if

	return res
end #function


"""

	geoEff(detector::WellDetector, aWellPnt::Point, SrcRadius::Real = 0.0, SrcLength::Real = 0.0)::Float64

**please refer to [`geoEff(::Detector, ::Point, ::Real, ::Real)`](@ref geoEff) for more information.**

!!! warning
    `aWellPNT` : point `height` is considered to be measured from the detector hole surface.

"""
function geoEff(detector::WellDetector, aWellPnt::Point, SrcRadius::Real = 0.0, SrcLength::Real = 0.0)::Float64
	
	pnt::Point = deepcopy(aWellPnt)
	Height = pnt.Height - detector.HoleDepth

	detin::CylDetector  = CylDetector(detector.HoleRadius, detector.HoleDepth)
	detout::CylDetector = CylDetector(detector.CryRadius , detector.CryLength)
	Point(Height, pnt); #0.0 == SrcRadius && Point(pnt, 0.0)

	if Height > 0.0							# the source as a whole out of the detector
		return geoEff(detout, Point(Height, pnt), SrcRadius, SrcLength)

	elseif Height + SrcLength < 0.0 		# the source as a whole inside of the detector
		return 1.0 - geoEff(detin, Point(-(Height + SrcLength), pnt), SrcRadius, SrcLength)

	elseif SrcLength > 0.0
		res = (1.0 - geoEff(detin, Point(0.0), SrcRadius, -Height)) * -Height/SrcLength
		res += geoEff(detout, Point(0.0), SrcRadius, Height + SrcLength) * (1.0 + Height/SrcLength)
		return res

	else
		return 1.0 - geoEff(detin, Point(-Height, pnt), SrcRadius)

	end #if
end #function

"""

	geoEff(detector::Detector, aPnt::Point, SrcRadius::Real = 0.0, SrcLength::Real = 0.0)::Float64

return the `geometrical efficiency` for a source (`point`, `disk` or `cylinder`) with 
the detector `detector`. 

## Arguments
*  `detector` can be any of the leaf detectors types (`CylDetector`, `BoreDetector`, `WellDetector`).
*  `aPNT`: a point represent the anchoring point of the source.
*  `SrcRadius`: Radius of the source.
*  `srcHeight`:  the height of an upright cylinder source.


## Throw
*  an `InValidGeometry` if the point location is invalide.
*  an `NotImplementedError` if source-to-detector geometry not supported yet.


!!! warning
    the point height of `aPnt` is measured differently for different detectors types.
    for the details, please refer to each detector entry.
	
!!! note
    *  if `SrcLength` equal to `zero`; the method return Geometrical Efficiency of a disc 
       source of Radius = `SrcRadius` and center at the point `aPNT`.
    *  if both `SrcRadius` and `SrcLength` equal to `zero`; 
       the method returns the Geometrical Efficiency of a point source at the anchoring point.

# Example

*   to obtain the efficiency of a `cylindrical` detector of crystal radius `2.0` cm for axial 
    source cylinder of radius `1.0` cm and height `2.5` cm on the detector surface. 

```jldoctest
julia> using GeoEfficiency

julia> geoEff(CylDetector(2.0), Point(0.0), 1.0, 2.5)
0.2923777934922748
```

*   to obtain the efficiency for a `bore-hole` detector of crystal radius of `2.0` and height of `3.0` with 
    hole radius of `1.5` cm for axial source cylinder of radius `1.0` cm and height `2.5` cm starting from detector center.

```jldoctest
julia> using GeoEfficiency

julia> newDet = BoreDetector(2.0, 3.0, 1.5);

julia> geoEff(newDet, Point(0.0), 1.0, 2.5)
0.5678174038944723
```

*   to obtain the efficiency for a `well-type` detector of crystal radius of `2.0` cm and 
    height `3.0` cm with hole radius of `1.5` cm and depth of `1.0` cm for axial source cylinder of 
    radius `1.0` cm and height `2.5` cm at the hole surface.
	
```jldoctest
julia> using GeoEfficiency

julia> newDet = WellDetector(2.0, 3.0, 1.5, 1.0);

julia> geoEff(newDet, Point(0.0), 1.0, 2.5)
0.4669614527701105
```

"""
geoEff

"""

	geoEff(detector::Detector = Detector(), aSource::Tuple{Point, Real, Real} = source())::Float64

same as `geoEff(::Detector, ::Point, ::Real, ::Real)` but splatting the argument 
in the Tuple `aSource`.

!!! note
    in the case of both no detector and no source Tuple or just the source Tuple is not supplied,
    it prompt the user to input a source (and detector) via the `console`.

"""
geoEff(detector::Detector = Detector(), aSource::Tuple{Point, Float64, Float64,} = source() )::Float64 = geoEff(detector, aSource...)
geoEff(detector::Detector, aSource::Tuple{Point, Real, Real,})::Float64 = geoEff(detector, aSource...)
