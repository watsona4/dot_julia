VERSION < v"0.7.0-rc1" && __precompile__()
module RangeArrays

using Compat

include("matrix.jl")
include("repeatedrange.jl")

export RangeMatrix, RepeatedRangeMatrix

end # module
