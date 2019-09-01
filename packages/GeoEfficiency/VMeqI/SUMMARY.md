# Summary

`GeoEfficiency` Package represent a fast and flexible tool to calculate in batch or individually the geometrical efficiency
for a set of common radiation detectors shapes (cylindrical, Bore-hole, Well-type) as seen form a source.
the source can be a point, a disc or even a cylinder.

## Requirements
 *  Julia 0.6 or above.
 *  QuadGK 0.3.0 or above, will be installed automatically while the package Installation.
 *  Compat 0.63.0 or above, will be installed automatically while the package Installation. 

## Download and Install the Package
	using Pkg
	Pkg.add("GeoEfficiency") 

## Quick Usage
 * geoEff()	: Calculate the `geometrical efficiency` for one geometrical setup return only the value of the geometrical efficiency.\n
	
 * calc() 	: Calculate the `geometrical efficiency` for one geometrical setup and display full information on the console.\n
	
 * calcN()	: Calculate the `geometrical efficiency` for geometrical setup(s) and display full information on the console until the user quit.\n
	
 * batch()	: Calculate the `geometrical efficiency` using data in the "GeoEfficiency" folder in batch mode.
 