# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

"""
    2D mortar contact mechanics for JuliaFEM.

# Problem types

- `Mortar2D` to couple non-conforming meshes (mesh tying).
- `MortarContact2D` to add contact constraints.

"""
module MortarContact2D

using FEMBase, SparseArrays, LinearAlgebra, Statistics

include("mortar2d.jl")
include("contact2d.jl")
export Mortar2D, Contact2D

end
