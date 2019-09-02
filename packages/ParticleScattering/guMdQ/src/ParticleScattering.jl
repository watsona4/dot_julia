"""
A Julia package for solving large-scale electromagnetic scattering problems in
two dimensions; specifically, those containing a large number of penetrable
smooth particles. Provides the ability to optimize over the particle parameters
for various design problems.
"""
module ParticleScattering

#Core functionality
using SpecialFunctions, IterativeSolvers, LinearMaps, Optim, SparseArrays, LinearAlgebra
import Statistics: mean
import LineSearches
#For plotting with PyPlot - actual import is done at runtime
using PyPlot, PyCall
const patch = PyNULL()
function __init__()
    copy!(patch, pyimport("matplotlib.patches")) #circles, polygons
end

include("PS_types.jl")
include("shapes.jl")
include("scattering.jl")
include("multipole.jl")
include("visualization.jl")
include("fmm_matrices.jl")
include("fmm_mvp.jl")
include("fmm_main.jl")
include("optimize_phis.jl")
include("optimize_rs.jl")
include("utilities.jl")
include("minimum_N_P.jl")
include("incident.jl")

#methods, shapes.jl
export rounded_star, squircle, ellipse, square_grid, rect_grid, hex_grid,
    randpoints, luneburg_grid, verify_min_distance
#methods, multipole.jl
export solve_particle_scattering, scattered_field_multipole
#methods, minimum_N_P.jl
export minimumN, minimumP
#methods, visualization.jl
export plot_far_field, plot_near_field, calc_near_field, draw_shapes
#methods, fmm_main.jl
export solve_particle_scattering_FMM
#methods, scattering.jl
export get_potential, get_potentialPW, scatteredfield
#types, PS_types.jl
export ScatteringProblem, OptimBuffer, FMMoptions, R_multipole,
    ShapeParams, CircleParams, AbstractShapeParams, PlaneWave, LineSource,
    CurrentSource, Einc
#methods, utilities.jl
export find_border, uniqueind
#methods, optimize_phis.jl
export optimize_φ
#methods, optimize_rs.jl
export optimize_radius
#methods, incident.jl
export uinc, hxinc, hyinc
#consts, incident.jl
export eta0

#temp
export divideSpace, FMMtruncation, particleExpansion, FMMbuildMatrices
export FMMbuffer, FMMmatrices

include("optimize_rs_mf.jl")
export optimize_rs_mf

include("poynting.jl")
export calc_power

include("optimize_rs_pwr.jl")
export PowerBuffer, OptimProblemBuffer, optMatrixPwr, optimize_pwr_rs_f, optimize_pwr_rs_g!
include("optimize_phis_pwr.jl")
export optimize_pwr_φ_f, optimize_pwr_φ_g!
end
