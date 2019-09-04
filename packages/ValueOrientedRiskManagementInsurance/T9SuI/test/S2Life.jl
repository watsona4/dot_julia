using ValueOrientedRiskManagementInsurance
using Distributions
using DataFrames
using LinearAlgebra

include("S2Life_Input.jl")
include("Life_Input.jl")
#################################################################
println("Start S2Life.jl")

t_0 = 0
cap_mkt = CapMkt(deepcopy(proc_stock), deepcopy(proc_rfr))

invs_par = Array{Any}(undef, 0)
push!(invs_par, mv_total_0, allocs, λ_invest)
invs = InvPort(t_0, T, cap_mkt, invs_par...)
product = Product(rfr_price, prob_price, β, λ_price)
liab_ins =
  LiabIns(t_0, prob_be, λ_be, cost_infl_be, product, df_portfolio)
liab_other = LiabOther(t_0, df_sub_debt)
dyn = Dynamic(T, bonus_factor, quota_surp)
proj = Projection(tax_rate, tax_credit_0,
                  cap_mkt, invs, liab_ins, liab_other, dyn)
param =
  ProjParam(t_0, T, cap_mkt, invs_par,
            liab_ins, liab_other, dyn, tax_rate, tax_credit_0)

s2 = S2(param,
        eq2type,
        ds2_mkt_all,
        ds2_def_all,
        ds2_life_all,
        s2_op,
        ds2_op,
        ds2)
s2.mds[1].scr
invs.igs[:IGStock].mv

println("Initial balance sheet:")
println(proj.val_0)
println("Modified Assets      : $(round(s2.invest_mod,
                                        digits = 2))")
println("Modified Liabilities : $(round(s2.liabs_mod,
                                        digits = 2))")
println("Risk Margin          : $(round(s2.risk_margin,
                                        digits = 2))")
println("Available capital    : $(round(s2.invest_mod -
                                        s2.liabs_mod -
                                        s2.risk_margin,
                                        digits = 2))")
println("SCR:                 : $(round(s2.scr, digits = 2))")
println("SCR-Ratio            : $(round(100 *s2.scr_ratio,
                                        digits = 1))%")

println("End S2Life.jl")
