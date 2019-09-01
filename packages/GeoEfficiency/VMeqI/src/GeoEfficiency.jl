__precompile__()

"""

# GeoEfficiency Package
introduce a fast and flexible tool to calculate in batch or individually the `geometrical efficiency` 
for a set of common radiation detectors shapes (cylindrical,Bore-hole, Well-type) as seen form 
a source. The source can be a point, a disc or even a cylinder.

# Quick Usage
*  geoEff()	: Calculate the geometrical efficiency for one geometrical setup return only the value of the geometrical efficiency.\n
*  calc() 	: Calculate the geometrical efficiency for one geometrical setup and display full information on the console.\n
*  calcN()	: Calculate the geometrical efficiency for geometrical setup(s) and display full information on the console until the user quit.\n
*  batch()	: Calculate the geometrical efficiency using data in the **`$(join(split(dataDir,"/travis")))`** folder in batch mode.

**for more information and updates refer to the repository at [`GitHub.com`](https://github.com/DrKrar/GeoEfficiency.jl/)**

"""
module GeoEfficiency

export 
	about,

 # Config

 # Input_Console

 # Physics_Model
	Point,
	source,
	Detector,
	CylDetector,
	BoreDetector,
	WellDetector,

# Input_Batch
	getDetectors,
	setSrcToPoint,
	typeofSrc,

 # Calculations
	geoEff,

 # Output_Interface
 	max_batch,
 	calc,
	calcN,
	batch,
	batchInfo

include("Config.jl") # to overwrite defaults edit parameters; restore by comment out this line.
include("Error.jl")	# define error system for the package.
include("Input_Console.jl")
include("Physics_Model.jl")
include("Input_Batch.jl")
include("Calculations.jl")
include("Output_Interface.jl")


#------------------------ about ---------------------------

using Compat, Compat.Dates

const abt ="""
\n
\t *************************************************
\t **            -=) GeoEfficiency (=-             **
\t **  Accurate Geometrical Efficiency Calculator  **
\t **   First Created on Fri Aug 14 20:12:01 2015  **
\t *************************************************

\t Author:        Mohamed E. Krar,  @e-mail: DrKrar@gmail.com 
\t Auth_Profile:  https://www.researchgate.net/profile/Mohamed_Krar3
\t Repository:    https://github.com/DrKrar/GeoEfficiency.jl/
\t Version:       v"0.9.3" - ($(Date(now()) - Date("2019-04-13")) old master)  
\t Documentation: https://GeoEfficiency.GitHub.io/index.html
\t PDF_Manual:    https://GeoEfficiency.GitHub.io/pdf/GeoEfficiency.pdf
\n
\n\tBatch mode 
\t-  read files by defaul from directory `$(join(split(dataDir,"/travis")))`
\t-  save results by default to directory `$(join(split(resultdir,"/travis")))`
\n\tfor more information see `batch`, `batchInfo`.
\n
"""

"$abt"
about() = printstyled(abt, color=:green, bold=true)
about()

end #module
