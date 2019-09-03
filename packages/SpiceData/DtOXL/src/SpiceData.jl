#SpiceData: A pure Julia SPICE data reader
#-------------------------------------------------------------------------------
__precompile__(true)

#=
TAGS:
	#WANTCONST, HIDEWARN_0.7
=#

module SpiceData

include("base.jl")
include("show.jl")


#==DataReader object: public members
================================================================================
	.sweepname
	.signalnames
	.sweep #Sweep values
==#

#==Exported symbols
===============================================================================#


#==Un-"exported" symbols
================================================================================
	_open(filepath::String)::DataReader
==#


#==Other interface tools (symbols not exported to avoid collisions):
================================================================================
#Already in base:
	Base.names(reader::DataReader)
	Base.read(reader::DataReader, signum::Int)
	Base.read(reader::DataReader, signame::String)
==#

end #module
