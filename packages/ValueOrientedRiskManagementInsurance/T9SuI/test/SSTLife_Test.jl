using ValueOrientedRiskManagementInsurance

using Distributions
using DataFrames
include("SSTLife_Input.jl")
include("SSTLife.jl")

println("Start SSTLife test")

@test round(rtk_start, digits = 2) ≈ 158.58
@test round(tc, digits = 2) ≈ 147.60
@test round(sst_ratio, digits = 4) ≈ 1.0744

println("End SSTLife test")
