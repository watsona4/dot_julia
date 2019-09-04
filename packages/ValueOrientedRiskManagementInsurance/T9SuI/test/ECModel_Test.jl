using ValueOrientedRiskManagementInsurance
using DataFrames
using Test

include("ECModel.jl")

println("Start ECModel test")

@test round(total.gross.profit_mean, digits = 2) ≈ 293.08
@test round(total.net.profit_mean, digits = 2) ≈ 249.39
@test round(total.gross.eco_cap, digits = 2) ≈ 1096.71
@test round(total.net.eco_cap, digits = 2) ≈ 823.70
@test round(total.gross.rorac, digits = 3) ≈ 0.267
@test round(total.net.rorac, digits = 3) ≈ 0.303
## risk adjusted pricing:
@test round(ins_input_rp[1, :loss_ratio], digits = 4) ≈ 0.7684
@test round(ins_input_rp[2, :loss_ratio], digits = 4) ≈ 0.7158
@test round(ins_input_rp[3, :loss_ratio], digits = 4) ≈ 0.7500
## capital optimization
@test round(rorac_net_oc[i_oc_opt], digits = 4) ≈ 0.2690
## product mix optimization, chosen quote f
@test round(avg_ceded_ofr, digits = 4) ≈ 0.4928
@test round(rorac_net_or_opt, digits = 4) ≈ 0.3376

println("End ECModel test")
