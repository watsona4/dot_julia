"""
    XFloats.jl

See: [`XFloat16`](@ref), [`XFloat32`](@ref)
"""
module XFloats


export XFloat16, XFloat32

import LinearAlgebra: (*), (/), (\), dot, cross, factorize, inv, det, logdet, logabsdet,
                      size, eigvals, eigvecs, svdvals
using LinearAlgebra
using Random

# import SpecialFunctions
# using SpecialFunctions

## ================================================================================ ##

"""
    XFloat16 is a floating point type

A more accurate alternative to Float16 that holds a Float32 and that performs as a Float32.
""" 
primitive type XFloat16 <: AbstractFloat 32 end

"""
    XFloat32 is a floating point type

A more accurate alternative to Float32 that holds a Float64 and that performs as a Float64.
""" 
primitive type XFloat32 <: AbstractFloat 64 end

XFloat16(x::XFloat16) = x
XFloat16(x::XFloat32) = reinterpret(XFloat16, Float32(reinterpret(Float64, x)))
XFloat32(x::XFloat16) = reinterpret(XFloat32, Float64(reinterpret(Float32, x)))
XFloat32(x::XFloat32) = x

XFloat16(x::Float32) = reinterpret(XFloat16, x)
Float32(x::XFloat16) = reinterpret(Float16, x)
XFloat32(x::Float64) = reinterpret(XFloat32, x)
Float64(x::XFloat32) = reinterpret(Float64, x)

include("type/construct.jl")
include("type/promote_convert.jl")
include("type/representations.jl")

include("imports.jl")
include("dispatch/specialize.jl")
include("dispatch/linearalgebra.jl")

end # module XFloats
