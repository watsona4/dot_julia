# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2DAD.jl/blob/master/LICENSE

"""
2D mortar contact mechanics for JuliaFEM using Automatic Differentiation
"""
module MortarContact2DAD

using FEMBase, ForwardDiff, LinearAlgebra, SparseArrays, Statistics

const MortarElements2D = Union{Seg2,Seg3}

include("mortar2dad.jl")
include("contact2dad.jl")
export Mortar2DAD, Contact2DAD

end
