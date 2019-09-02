#PhysicalCommunications:
#-------------------------------------------------------------------------------

module PhysicalCommunications

include("functions.jl")
include("prbs.jl")
include("eyediag.jl")


#==Exported interface
===============================================================================#
export MaxLFSR #Create MaxLFSR iterator object.
export sequence #Builds sequences with LFSR objects
export sequence_detecterrors #Tests validity of bit sequence using sequence generator algorithm
export buildeye


#==Unexported interface
================================================================================
	.DataEye #Stores eye data
==#

end # module

#Last line
