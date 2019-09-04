using ValueOrientedRiskManagementInsurance

using Distributions
using DataFrames
using Test

include("S2NonLife.jl")

println("Start S2NonLife test")

@test round(scr_prem_res, digits = 2) ≈ 210.95
@test round(scr_lapse, digits = 2) ≈ 0.0
@test round(scr_cat_fire, digits = 2) ≈ 60.00
@test round(scr_cat_liab, digits = 2) ≈ 239.65
@test round(scr_cat_man_made, digits = 2) ≈ 247.05
@test round(scr_cat_other, digits = 2) ≈ 0.0
@test round(scr_cat_nprop, digits = 2) ≈ 0.0
@test round(scr_cat, digits = 2) ≈ 247.05
@test round(scr_nl, digits = 2) ≈ 362.76

println("End S2NonLife test")
