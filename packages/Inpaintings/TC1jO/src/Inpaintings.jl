module Inpaintings
# This module translates the `inpaint_nans` MATLAB code from John d'Erico

using SparseArrays, SuiteSparse, LinearAlgebra
using Match

include("inpaint.jl")

end # module
