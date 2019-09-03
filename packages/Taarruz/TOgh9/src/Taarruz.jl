module Taarruz
using Knet


_etype = gpu() >= 0 ? Float32 : Float64
_atype = gpu() >= 0 ? KnetArray{_etype} : Array{_etype}


"""
    FloatArray
A KnetArray or Array. Its elements should be Float32 or Float64.
"""
const FloatArray = Union{KnetArray{F}, Array{F}} where F <: AbstractFloat


include("attacks.jl"); export FGSM
include("lenet.jl"); export Lenet


end # module
