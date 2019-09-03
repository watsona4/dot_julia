module StanMCMCChain

# package code goes here

using Reexport 

@reexport using CmdStan, MCMCChain, Plots, Statistics, JLD
import CmdStan: convert_a3d

include("utilities/convert_a3d.jl")
#include("utilities/jld.jl")

export
  convert_a3d

end # module
