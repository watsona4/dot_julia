module DynACof

using DataFrames
using CSV
import ProgressMeter.Progress, ProgressMeter.next!
import Dates
import ForwardDiff.derivative # To find Δ (esat slope)
import Optim.optimize, Optim.minimizer
import Interpolations.LinearInterpolation


# Helper functions:
export is_missing, warn_var, previous_i
export cos°,sin°,tan°,acos°,asin°,atan°
export logistic,logistic_deriv,mean,diff
# ecophysio helpers:
export rH_to_VPD,esat,esat_slope,GDD
export virtual_temp,VPD_to_e,dew_point,paliv_dis,CN,Sucrose_cont_perc
export PENMON,psychrometric_constant,latent_heat_vaporization,air_density,LE_to_ET,ET_to_LE
# Meteorology helpers
export Rad_ext,diffuse_fraction,pressure_from_elevation,sun_zenithal_angle
export Rad_net,days_without_rain
# Parameters-related functions
export import_parameters
export constants,site,coffee,soil,tree
export struct_to_tuple
export read_param_file
export CB,LeafWaterPotential,T_Coffee,H_Coffee,lue,Metamodels_soil
export light_extinction_K_Tree,tree_allometries,metamodels_tree
# initialization
export initialise!
# Conductances
export GetWind,G_bulk,Gb_h,G_soilcan,G_interlay
# Diseases
export ALS
# Main functions:
export meteorology
export dynacof, mainfun, Shade_Tree, soil_model!, coffee_model!,balance_model!
export dynacof_i!

include("test.jl")
include("helpers.jl")
include("meteo.jl")
include("parameters_struct.jl")
include("ecophysio_helpers.jl")
include("meteorology_helpers.jl")
include("import_parameters.jl")
include("initialization.jl")
include("conductances.jl")
include("bud_init.jl")
include("balance.jl")
include("coffee.jl")
include("diseases.jl")
include("tree_dcm.jl")
include("soil.jl")
include("main.jl")

end # module
