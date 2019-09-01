using EmpiricalModeDecomposition
using Test

emd_dir = joinpath(dirname(pathof(EmpiricalModeDecomposition)), "..")

# Conduct Testing
include("$(emd_dir)/test/basic_emd.jl")
include("$(emd_dir)/test/basic_eemd.jl")
