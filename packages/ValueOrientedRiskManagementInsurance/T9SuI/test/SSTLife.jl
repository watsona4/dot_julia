using ValueOrientedRiskManagementInsurance

using Distributions
using DataFrames
include("SSTLife_Input.jl")

#################################################################
println("Start SSTLife.jl")

Random.seed!(seed) ## fix random seed for repeatable results

## Setting up capital market, investments, liabilities ----------
cap_mkt = SSTCapMkt(deepcopy(spot), deepcopy(stock_increase))

assets = Array{Asset}(undef, 0)
for 𝑟𝑜𝑤 ∈ 1:nrow(invest)
  if invest[𝑟𝑜𝑤, :kind] == "stock"
    push!(assets, StockIndex(invest[𝑟𝑜𝑤, :nominal],
                             invest[𝑟𝑜𝑤, :index]))
  else ## zero bond
    push!(assets, ZeroBond(invest[𝑟𝑜𝑤, :nominal],
                           invest[𝑟𝑜𝑤, :maturity],
                           invest[𝑟𝑜𝑤, :index]))
  end
end

liabs =   Liabilities(B_PX, qx, index_mort)

## setting up risk factors
rf = RiskFactor(σ , corr,
                [x0_spot; x0_stock; x0_mort],
                [h_spot; h_stock; h_mort],
                [add_spot; add_stock; add_mort])

## scenarios ----------------------------------------------------
Γ = gammamatrix(assets, liabs, rf, cap_mkt)
δ = delta(assets, liabs, rf, cap_mkt)
for 𝑖 = 1:stress.n
  stress.Δrtk[𝑖] =  Δrtk(vec(stress.Δx[𝑖, :]), δ, Γ)
end

## distribution of the rtk --------------------------------------
## only market risk: _mkt
## onlu insurance risk: _ins
## both market and insurance risk: __mkt_ins
## market and insurance risk, as well as stress: _mkt_ins_stress
index_mkt = [index_spot; index_stock]
index_ins = collect(index_mort)
index_mkt_ins = [index_mkt; index_ins]
r_Δrtk_mkt = rΔrtk(n_scen, assets, liabs, rf, cap_mkt, index_mkt)
r_Δrtk_ins = rΔrtk(n_scen, assets, liabs, rf, cap_mkt, index_ins)
r_Δrtk_mkt_ins =
  rΔrtk(n_scen, assets, liabs, rf, cap_mkt, index_mkt_ins)
r_Δrtk_mkt_ins_stress = aggrstress(stress, r_Δrtk_mkt_ins)

## corresponding expectes shortfall
c_mkt = es(-r_Δrtk_mkt, α)
c_ins = es(-r_Δrtk_ins, α)
c_mkt_ins = es(-r_Δrtk_mkt_ins, α)
c_mkt_ins_stress = es(-r_Δrtk_mkt_ins_stress,α)

## calculation of market value margin ---------------------------
c_fac =
  [value(𝑡, liabs, rf.x0, rf, cap_mkt) /
     value(0, liabs, rf.x0, rf, cap_mkt) for 𝑡 ∈ 1:T]
c_fut_ins_stress =
  c_fac * (c_mkt_ins_stress - c_mkt_ins + c_ins)
mvm_start =
  sum([c_fut_ins_stress[𝑡] * coc_rate / (1 + cap_mkt.spot[𝑡])^𝑡
       for 𝑡 ∈ 1:T])
mvm = mvm_start * (1 + cap_mkt.spot[1])

## target capital and sst ratio ---------------------------------
rtk_start = rtk(0, assets, liabs, rf.x0, rf, cap_mkt)
tc = ( c_mkt_ins_stress - cap_mkt.spot[1] * rtk_start + mvm) /
  (1 + cap_mkt.spot[1])
sst_ratio = rtk_start/tc

## main results ------------------------------------------------
println("rtk_start     :  $(round(rtk_start, digits = 2))")
println("target capital:  $(round(tc, digits = 2))")
println("sst ratio     :  $(round(sst_ratio, digits = 2))")

println("End SSTLife.jl")
