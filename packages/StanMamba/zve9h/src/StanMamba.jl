module StanMamba

# package code goes here
using Statistics, Documenter

import CmdStan: convert_a3d
#import Mamba: AbstractChains, Chains


abstract type AbstractChains end

struct Chains <: AbstractChains
  value::Array{Float64, 3}
  range::UnitRange{Int}
  names::Vector{AbstractString}
  chains::Vector{Int}
end


include("utilities/convert_a3d.jl")

export
  convert_a3d
  
end # module
