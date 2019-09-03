module StanMCMCChains

# package code goes here

using Reexport 

@reexport using CmdStan, MCMCChains, Plots, Statistics, JLD
import CmdStan: convert_a3d

include("utilities/convert_a3d.jl")

export
  convert_a3d

end # module
