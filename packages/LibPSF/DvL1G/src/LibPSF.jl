#LibPSF: A pure Julia implementation of LibPSF
#-------------------------------------------------------------------------------
__precompile__(true)
#=
TAGS:
	#WANTCONST, HIDEWARN_0.7
=#

module LibPSF

include("base.jl")
include("deserialize.jl")
include("deserialize_sweep.jl")
include("interface.jl")


#==Exported symbols
===============================================================================#
export readsweep


#==Un-"exported" symbols
================================================================================
	_open(filepath::String)::DataReader
==#

#="Base" LibPSF functions
	is_swept, get_nsweeps
	get_signal_names
	get_sweep_param_names
	get_sweep_npoints
	get_sweep_values
	get_signal_vector(reader::DataReader, signame::String)
	get_signal_scalar(reader::DataReader, signame::String)
	get_signal(reader::DataReader, signame::String)
=#


#==Other interface tools (symbols not exported to avoid collisions):
================================================================================
#Already in base:
	Base.names(reader::DataReader)
	Base.read(reader::DataReader, signame::String)
==#

end #LibPSF
#Last line
