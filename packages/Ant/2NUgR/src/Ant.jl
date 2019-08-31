#!/usr/bin/env julia
#=
Package Gnar
del2z <delta.z@aliyun.com>
=#
module Gnar

include("struct.jl")
export Polar, Model

include("data/Data.jl")
include("wordvec/WordVec.jl")

end # module
