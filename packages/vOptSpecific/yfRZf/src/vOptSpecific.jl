# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
module vOptSpecific

using Compat

const libLAPpath = joinpath(@__DIR__, "..", "deps", "libLAP.so")
const libUMFLPpath = joinpath(@__DIR__, "..", "deps", "libUMFLP.so")
const libcomboPath = joinpath(@__DIR__,"..","deps","libcombo.so")

include("LAP.jl")
include("UMFLP.jl")
include("jMOScheduling.jl")
include("Bi01KP/Bi01KP.jl")
include("KP.jl")

@static if VERSION > v"0.7-"
	using DelimitedFiles
	using SparseArrays
	_unsafe_wrap(Atype, p, dims ; own=false) = unsafe_wrap(Atype, p, dims, own=own)
end

@static if VERSION < v"0.7-"
	_unsafe_wrap(Atype, p, dims ; own=false) = unsafe_wrap(Atype, p, dims, own)
end

export vSolve,
    load2LAP, set2LAP, LAP_Przybylski2008,
    load2OSP, set2OSP, OSP_VanWassenhove1980, generateHardInstance,
    load2UMFLP, set2UMFLP, UMFLP_Delmee2017,
    load2UKP, set2UKP, UKP_Jorge2010


__init__() = (!isfile(libLAPpath) || !isfile(libUMFLPpath)) || !isfile(libcomboPath) && warn("""Some libraries are missing, run Pkg.build("vOptSpecific")""")

end # module
