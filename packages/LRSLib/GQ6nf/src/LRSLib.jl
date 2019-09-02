module LRSLib

using BinDeps
using Polyhedra

if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
    else
    error("LRSLib not properly installed. Please run Pkg.build(\"LRSLib\")")
end

macro lrs_ccall(f, args...)
    quote
        ret = ccall(($"lrs_$f", liblrs), $(map(esc,args)...))
        ret
    end
end
macro lrs_ccall2(f, args...)
    quote
        ret = ccall(($"$f", liblrs), $(map(esc,args)...))
        ret
    end
end


include("lrstypes.jl")

if Clrs_false == (@lrs_ccall init Clong (Ptr{Cchar},) C_NULL)
    error("Initialization of LRS failed")
end

include("matrix.jl")
include("conversion.jl")
include("redund.jl")
include("polyhedron.jl")

end # module
