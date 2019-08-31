module BHAtp

# package code goes here

using Reexport, DataFrames, Statistics

if VERSION.minor > 6
  @eval using SparseArrays, LinearAlgebra 
end

@reexport using PtFEM

include("p44_1.jl")

export
  p44_1

end # module
