# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

"""
    FEMBeam

Beam implementation for JuliaFEM.

# Supported beams

- Euler-Bernoulli beam in 3D. Approximation of displacement field is done using
  Hermite C1-continuous interpolation polynomials in bending and C0-continuous
  Lagrange interpolation polynomials is axial direction and twisting. Each node
  has 6 degrees of freedom.

"""
module FEMBeam

using FEMBase, LinearAlgebra, SparseArrays

include("get_beam_stiffness_matrix_2d.jl")
include("get_beam_forces_vector_2d.jl")
include("get_beam_mass_matrix_2d.jl")
include("beam2d.jl")
export Beam2D

include("beam3d.jl")
export Beam

end
