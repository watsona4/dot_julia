module StanDataFrames

using Statistics, DataFrames, Documenter
import CmdStan: convert_a3d

# package code goes here

include("utilities/convert_a3d.jl")

export
  convert_a3d

end # module
