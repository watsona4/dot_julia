module ParSpMatVec
using SparseArrays
using LinearAlgebra
using Libdl
const spmatveclib  = abspath(joinpath(splitdir(Base.source_path())[1],"..","deps","builds","ParSpMatVec"))


include("A_mul_B.jl")
include("Ac_mul_B.jl")


export isBuilt
function isBuilt()
	println(spmatveclib)
	return find_library([spmatveclib])!=""
end


end # module
