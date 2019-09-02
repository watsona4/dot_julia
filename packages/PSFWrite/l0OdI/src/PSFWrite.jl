#PSFWrite: Write data to a Parameter Storage Format (PSF) file
#-------------------------------------------------------------------------------
#=
TAGS:
	#WANTCONST, HIDEWARN_0.7
=#

module PSFWrite

import Dates: now

include("base.jl")
include("sections_main.jl")
include("sections_values.jl")
include("interface.jl")


#==Exported symbols
===============================================================================#


#==Un-"exported" symbols (symbols not exported to avoid collisions):
================================================================================
	_open(filepath::String)::PSFWriter

Create a PSFSweptDataset:
	dataset(sweep::Vector, sweepid::String)::PSFSweptDataset
==#


#==Methods extending already exported symbols:
================================================================================

#Add another vector to be written:
	Base.push!(ds::PSFSweptDataset, vec::Vector, id::String)

#Write dataset to file:
	Base.write(writer::PSFWriter, ds::PSFSweptDataset)
	...
==#

end #PSFWrite

#Last line
