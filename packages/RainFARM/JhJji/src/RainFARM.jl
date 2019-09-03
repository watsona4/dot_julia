# RainFARM:  Stochastic downscaling following 
# - *D'Onofrio et al. 2014, J of Hydrometeorology 15 , 830-843* and
# - *Rebora et. al 2006, JHM 7, 724* 
# Includes orographic corrections
# Implementation in Julia language

# Copyright 2016 Jost von Hardenberg
#
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, 
# software distributed under the License is distributed on an 
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. 
# See the License for the specific language governing permissions 
# and limitations under the License.

__precompile__()
module RainFARM
export agg, fft3d, initmetagauss, gaussianize, metagauss, smoothconv, smoothspec
export mergespec_spaceonly, downscale_spaceonly, lon_lat_fine, fitslopex
export read_netcdf2d, write_netcdf2d, rainfarm, interpola, smooth
export overwrite_netcdf2d, rfweights

using Interpolations, NetCDF, Compat
using Compat.Statistics, Compat.Printf, Compat.SparseArrays
if VERSION >= v"0.7.0-DEV.2005"
    using FFTW
end

include("rf/agg.jl")
include("rf/smoothconv.jl")
include("rf/smoothspec.jl")
include("rf/smooth.jl")
include("rf/fft3d.jl")
include("rf/initmetagauss.jl")
include("rf/gaussianize.jl")
include("rf/metagauss.jl")
include("rf/mergespec_spaceonly.jl")
include("rf/downscale_spaceonly.jl")
include("rf/lon_lat_fine.jl")
include("rf/fitslopex.jl")
include("rf/read_netcdf2d.jl")
include("rf/write_netcdf2d.jl")
include("rf/overwrite_netcdf2d.jl")
include("rf/interpola.jl")
include("rf/rainfarm.jl")
include("rf/rfweights.jl")

end
