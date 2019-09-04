using ValueOrientedRiskManagementInsurance
using DataFrames
using LinearAlgebra
using Test
import LinearAlgebra.⋅

include("S2Life.jl")
VORMI = ValueOrientedRiskManagementInsurance

println("Start S2Life test")

ins_sum = df_portfolio[1, :ins_sum]

for 𝑡 ∈ 1: T
  @test prob_price[1, :sx] == prob_price[𝑡, :sx]
  @test rfr_price[1] == rfr_price[𝑡]
  @test λ_price[1, :infl] == λ_price[𝑡, :infl]
  @test λ_price[1, :eoy] == λ_price[𝑡, :eoy]
  if 𝑡 > 1
    @test λ_price[𝑡, :boy] == 0
  end
  @test  convert(Array, β[:sx]) == cumsum(fill(β[1, :sx], 5))
  ## following is used in presentation of pricing calculation:
  @test prob_price[𝑡, :qx] ≈ (10 + 𝑡 -1)/10000
end

for 𝑖 ∈ 1:nrow(df_portfolio)
  @test df_portfolio[𝑖, :ins_sum] == ins_sum
end

## Premium ------------------------------------------------------
prob_price[:px] = 1 .- prob_price[:, :qx] .- prob_price[1, :sx]
lx_price_boy =
  convert(Array, cumprod(prob_price[:px]) ./ prob_price[:px])

v_price_eoy = cumprod(1 ./ (1 .+ rfr_price))
v_price_boy = v_price_eoy .* (1 .+ rfr_price)

infl_price_eoy = convert(Array, cumprod(1 .+ λ_price[:infl]))
infl_price_boy =
  infl_price_eoy ./ convert(Array, 1 .+ λ_price[:infl])

prem_price_ratio =
  sum(lx_price_boy .* v_price_boy .*
      λ_price[:, :boy] .* infl_price_boy +
        lx_price_boy .* v_price_eoy .*
      (λ_price[:, :eoy] .* infl_price_eoy +
         prob_price[:, :qx] .* β[:, :qx] +
         prob_price[:, :px] .* β[:, :px])) /
  sum(lx_price_boy .* v_price_boy -
        prob_price[:, :sx] .*
      β[:, :sx] .* lx_price_boy .* v_price_eoy)

for 𝑖 ∈ 1:nrow(df_portfolio)
  for 𝑡 ∈ 1:𝑖
    @test prem_price_ratio ≈ liab_ins.mps[𝑖].β[𝑡, :prem] ./
                             liab_ins.mps[𝑖].β[𝑡, :qx]
  end
end

prem_price = prem_price_ratio * ins_sum

## techn. prov. (pricing) calc ----------------------------------
tp_price = zeros(Float64, T)
for 𝑡 ∈ (T-1):-1:1
  tp_price[𝑡] =
    - prem_price +
    1 / (1 + rfr_price[𝑡 + 1]) *
    (λ_price[𝑡 + 1, :eoy] * infl_price_eoy[𝑡 + 1] *ins_sum +
       prob_price[𝑡+1, :qx] * ins_sum +
       prob_price[𝑡 + 1, :sx] * β[𝑡 + 1, :sx] * prem_price +
       prob_price[𝑡 + 1, :px] * (β[𝑡 + 1, :px] * ins_sum +
                                   tp_price[𝑡 + 1]))
end

for 𝑖 ∈ 1:nrow(df_portfolio)
  t_contract = T + df_portfolio[𝑖, :t_start]
    @test tp_price[T-t_contract+1:T] ≈ liab_ins.mps[𝑖].tpg_price/
                                       df_portfolio[𝑖, :n]
end

## best estimate assumptions ------------------------------------

y_stock =
  vcat(proc_stock.x[1]/proc_stock.x_0 - 1,
       Float64[proc_stock.x[t] / proc_stock.x[t-1] - 1 for t in 2:T])
delta_qx = prob_price[1, :qx] - prob_be[1, :qx]
for 𝑡 ∈ 1:T
  @test y_stock[𝑡] ≈ proc_stock.x[1]-1
end
for 𝑡 ∈ 1:T
  @test prob_be[𝑡, :qx] + delta_qx == prob_price[𝑡, :qx]
end

## Costs ========================================================

## In our example the cost inflation is constant in time
for 𝑑 ∈ 1:nrow(df_portfolio)
  for 𝑥 ∈ cost_infl_be[𝑑]
    @test 𝑥 == cost_infl_be[1][1]
  end
end
## In our example all costs are constant in time
for 𝑡 ∈ 1:T
  if 𝑡 > 1
    @test  λ_be[𝑡, :boy] == 0
  end
  @test λ_be[1, :eoy] == λ_be[𝑡, :eoy]
  @test λ_invest[:IGCash][1, :rel] == λ_invest[:IGCash][𝑡, :rel]
  @test λ_invest[:IGCash][1, :abs] == λ_invest[:IGCash][𝑡, :abs]
  @test λ_invest[:IGStock][1, :rel] == λ_invest[:IGStock][𝑡, :rel]
  @test λ_invest[:IGStock][1, :abs] == λ_invest[:IGStock][𝑡, :abs]
end

## State of the economy =========================================

## notice that indices of tmp_stock, tmp_state are shifted by one
tmp_stock = [cap_mkt.stock.x_0; cap_mkt.stock.x]
state = Float64[(tmp_stock[𝑡+1]/tmp_stock[𝑡]-1-rfr[𝑡])/rfr[𝑡]
                for 𝑡 ∈ 1:T]
tmp_state =
  [cap_mkt.stock.yield_0 / cap_mkt.rfr.yield_0 - 1; state]
state_avg =
  Float64[(tmp_state[𝑡 + 1] + tmp_state[𝑡]) / 2 for 𝑡 ∈ 1:T]

allocation = 0.5 * (1 .- exp.(-max.(0, state_avg)))
## restore initial allocation
allocation[1] = invs.igs[:IGStock].alloc.total[1]

state_orig =
  Float64[VORMI.dynstate(𝑡,cap_mkt) for 𝑡 ∈ 1:T]
state_avg_orig =
  Float64[VORMI.dynstateavg(𝑡,cap_mkt) for 𝑡 ∈ 1:T]
@test state ≈ state_orig
@test state_avg ≈ state_avg_orig
@test allocation ≈ invs.igs[:IGStock].alloc.total

y_invest =
  Float64[allocation[𝑡] * y_stock[𝑡] + (1-allocation[𝑡]) * rfr[𝑡] for 𝑡 ∈ 1:T]

t_bonus_quota = dyn.bonus_factor * (y_invest - rfr_price)

sx_basis = Array{Vector{Float64}}(undef, nrow(df_portfolio))
for 𝑖 ∈ 1:nrow(df_portfolio)
  sx_basis[𝑖] = convert(Array, liab_ins.mps[𝑖].prob[:sx])
end

v_eoy = cumprod(1 ./ (1 .+ rfr))
v_boy = v_eoy .* (1 .+ rfr)

infl_eoy = cumprod(1 .+ cost_infl_be[end])
infl_boy = infl_eoy ./ (1 .+ cost_infl_be[end])

prob = deepcopy(prob_be)
prob[:px] = 1 .- prob[:qx] - prob[:sx]

rfr_cost = rfr - λ_invest[:IGCash][:, :rel]

function tpberec(tp_next, t, τ, prob_sx)
  prob_px = 1 .- prob[:qx] - prob_sx

  - prem_price +
    λ_be[t + τ - t_0 + 1, :boy] * infl_boy[t + 1] * ins_sum +
    1 / (1 + rfr[t + 1]) *
      (λ_be[t + τ - t_0 + 1, :eoy] * infl_eoy[t + 1] * ins_sum +
      prob[t + τ - t_0 + 1, :qx] * ins_sum +
      prob_sx[t + τ - t_0 + 1] * β[t + τ - t_0 + 1, :sx] * prem_price +
      prob_px[t + τ - t_0 + 1] * (β[t + τ - t_0 + 1, :px] * ins_sum + tp_next))
end

τ=1
d=4
t=3
prem_price
mp = deepcopy(liab_ins.mps[d])
fn = df_portfolio[d, :n]
prob_sx = convert(Array, prob[:sx]) * df_portfolio[d, :sx_be_fac]
prob_px = 1 .- prob[:qx] - prob_sx
@test fn * prem_price ≈ mp.β[t+1, :prem]
@test mp.λ[t + 1, :boy] *  mp.λ[t + 1, :cum_infl] /
      (1 + mp.λ[t + 1, :infl]) ≈
      λ_be[t + τ - t_0 + 1, :boy] * infl_eoy[t + 1] * ins_sum
disc = 1/(1 + rfr[t + 1])
@test 1 / (1 + rfr_cost[t + 1]) ≈
      disc/(1 - disc * invs.igs[:IGCash].cost.rel[τ + 1])
@test fn * λ_be[t + τ - t_0 + 1, :eoy] *
      infl_eoy[t + 1] * ins_sum ≈
      mp.λ[t + 1, :eoy] * mp.λ[t + 1, :cum_infl]
@test fn * λ_be[t + τ - t_0 + 1, :eoy] * ins_sum ≈
      mp.λ[t + 1, :eoy]

@test fn * prob[t + τ - t_0 + 1, :qx] * ins_sum  ≈
      mp.prob[t + 1, :qx] * mp.β[t + 1, :qx]
@test fn * prob_sx[t + τ - t_0 + 1] *
      β[t + τ - t_0 + 1, :sx] * prem_price ≈
      mp.prob[t + 1, :sx] * mp.β[t + 1, :sx]
@test fn * prob_px[t + τ - t_0 + 1] *
      (β[t + τ - t_0 + 1, :px] * ins_sum) ≈
      mp.prob[t + 1, :px] * (mp.β[t + 1, :px] + 0)


## Going concern ================================================
tmp_gc = zeros(Float64, T)
for 𝑑 ∈ 1:nrow(df_portfolio)
  lx_boy = df_portfolio[𝑑, :n]
  tmp_gc[1] += lx_boy
  for 𝑡 = 2:nrow(liab_ins.mps[𝑑].prob)
    lx_boy *=
      (1 - liab_ins.mps[𝑑].prob[𝑡 - 1,:qx] -
         liab_ins.mps[𝑑].prob[𝑡 - 1,:sx])
    tmp_gc[𝑡] += lx_boy

  end
end
tmp_gc /= sum(df_portfolio[:n])

@test tmp_gc ≈ liab_ins.gc

tmp_gc_extension = [liab_ins.gc; 0]
tmp_Δgc = zeros(Float64,T)
for 𝑡 ∈ 1:T
  tmp_Δgc[𝑡] = tmp_gc_extension[𝑡+1] - tmp_gc_extension[𝑡]
end
@test liab_ins.Δgc ≈ tmp_Δgc

## Going concern absolute costs ---------------------------------
cost_abs =
  Float64[liab_ins.gc[𝑡] *
            (λ_invest[:IGCash][𝑡, :abs] *
               prod(1 .+ (λ_invest[:IGCash][1:𝑡, :infl_abs])) +
               λ_invest[:IGStock][𝑡, :abs] *
               prod(1 .+ (λ_invest[:IGStock][1:𝑡, :infl_abs])))
          for 𝑡 ∈ 1:T]

@test proj.fixed_cost_gc ≈ cost_abs

## Subordinated debt --------------------------------------------
# cf_liab_other_unscaled =
#   fill(-df_sub_debt[1, :coupon], df_sub_debt[1, :t_mat] - t_0)
# cf_liab_other_unscaled[df_sub_debt[1, :t_mat] - t_0] -=
#   df_sub_debt[1, :nominal]

l_other = deepcopy(liab_other)
VORMI.goingconcern!(l_other, liab_ins.Δgc)
cf_l_other = Array{Vector{Float64}}(undef, T)
for 𝑡 ∈ 1:T
  cf_l_other[𝑡] = zeros(Float64, l_other.subord[𝑡].τ_mat)
  fill!(cf_l_other[𝑡], -l_other.subord[𝑡].coupon)
  cf_l_other[𝑡][l_other.subord[𝑡].τ_mat] -=
    l_other.subord[𝑡].nominal
end

cf_l_other_total = zeros(Float64, T)
for 𝑡 ∈ 1:T
  cf_l_other_total[1:𝑡] += cf_l_other[𝑡]
end

@test sum([cf_l_other[𝑡][end] for 𝑡 ∈ 1:T]) ≈
      -df_sub_debt[1, :coupon] - df_sub_debt[1, :nominal]
for 𝑡 ∈ 2:T
  @test cf_l_other[𝑡][1] / cf_l_other[𝑡][end]  ≈
        df_sub_debt[1, :coupon] /
        (df_sub_debt[1, :coupon] + df_sub_debt[1, :nominal])
end
@test sum(-[cumprod(1 ./ (1 .+ rfr))[1:𝑡] ⋅ cf_l_other[𝑡]
            for 𝑡 ∈ 1:T]) ≈
      proj.val_0[1, :l_other]


for 𝑑 = 1:(T-1)
  @test (-cumprod(1 ./ (1 .+ rfr[𝑑+1:T])) ⋅
        cf_l_other_total[𝑑+1:T]) ≈
        proj.val[𝑑, :l_other]
end

## gc surplus adjustment ----------------------------------------
@test proj.cf[:gc] ≈
      (proj.val_0[1, :invest] -
        proj.val_0[1, :tpg]-
        proj.val_0[1, :l_other]) *
       liab_ins.Δgc


## Technical provisions for guaranteed benefits, t = 0 ==========

tp = Array{Vector{Float64}}(undef, nrow(df_portfolio))
tp_0 = zeros(Float64, nrow(df_portfolio))

for 𝑑 ∈ 1:nrow(df_portfolio)
  # d = 4
  tp[𝑑] = zeros(Float64, T)
  local prob_sx =
    convert(Array, prob[:sx]) * df_portfolio[𝑑, :sx_be_fac]
  local τ = t_0 - df_portfolio[𝑑, :t_start]
  for 𝑡 ∈ (T-1-τ):-1:(1)
    tp[𝑑][𝑡] = tpberec(tp[𝑑][𝑡 + 1], 𝑡, τ, prob_sx)
  end
  tp_0[𝑑] = tpberec(tp[𝑑][1], 0, τ, prob_sx)
end


for 𝑑 ∈ 1:nrow(df_portfolio)
  for 𝑡 ∈ 1:(T + df_portfolio[𝑑, :t_start])
    @test VORMI.tpg(𝑡, cap_mkt.rfr.x, liab_ins.mps[𝑑]) ≈
          df_portfolio[𝑑, :n] * tp[𝑑][𝑡]
  end
end

lx = zeros(Float64, T+1)
tp_all_0 = 0.0
for 𝑑 ∈ 1:nrow(df_portfolio)
  local τ = t_0 - df_portfolio[d, :t_start]
  lx[1] = 1.0
  global tp_all_0 += lx[1] * tp_0[𝑑] * df_portfolio[𝑑, :n]
  for 𝑡 ∈ 1:T
    if 𝑡 + τ - t_0 <= T
      lx[𝑡 + 1] = lx[𝑡] * prob[𝑡 + τ - t_0, :px]
    end
  end
end

@test tp_all_0 ≈ proj.val_0[1, :tpg]

## Cashflows year 1 =============================================

## bi-quotient --------------------------------------------------
@test VORMI.bonusrate(1, y_invest[1], liab_ins.mps[1], dyn) ≈
      t_bonus_quota[1]
@test VORMI.getyield(1, cap_mkt.rfr) ≈ rfr[1]
@test VORMI.getyield(1, cap_mkt.stock) ≈ y_stock[1]

ind_bonus_1 =
  y_stock[1] / (t_bonus_quota[1] + liab_ins.mps[1].rfr_price[1])

@test VORMI.getyield(0, cap_mkt.stock) ≈ cap_mkt.stock.yield_0
@test VORMI.getyield(0, cap_mkt.rfr) ≈ cap_mkt.rfr.yield_0

ind_bonus_hypo =
  cap_mkt.stock.yield_0 /
  (liab_ins.mps[1].bonus_rate_hypo + liab_ins.mps[1].rfr_price_0)

bi_quot_1 =ind_bonus_1 / ind_bonus_hypo

@test bi_quot_1 ≈ VORMI.biquotient(1,
                                   y_invest[1],
                                   cap_mkt, invs,
                                   liab_ins.mps[1],
                                   dyn)

## In the text we assume that b^C,hypo does not depend on C
for 𝑑 ∈ 2:nrow(df_portfolio)
  @test df_portfolio[1,:bonus_rate_hypo] ≈
        df_portfolio[𝑑,:bonus_rate_hypo]
end

## δ_sx_one, qx_one, sx_one, px_one are vectors
## over all model points for time t == 1
δ_sx_one =
  Float64[VORMI.δsx(1, cap_mkt, invs, liab_ins.mps[𝑑], dyn)
   for 𝑑 ∈ 1:nrow(df_portfolio)]

t = 1
for 𝑑 ∈ 1:nrow(df_portfolio)
  if length(sx_basis[𝑑]) >= t
    @test sx_basis[𝑑][t] ≈ liab_ins.mps[𝑑].prob[t, :sx]
  end
end

sx_one = δ_sx_one .* Float64[sx_basis[𝑑][1] for 𝑑 ∈ 1:nrow(df_portfolio)]

qx_one =
  Float64[liab_ins.mps[𝑑].prob[t, :qx]
          for 𝑑 ∈ 1:nrow(df_portfolio)]
px_one = 1 .- qx_one .- sx_one

## Cashflows ----------------------------------------------------

cf_prem_one =
  sum([liab_ins.mps[𝑑].β[1,:prem] for 𝑑 ∈ 1:nrow(df_portfolio)])
cf_λ_boy_one =
  -sum([liab_ins.mps[𝑑].λ[1,:boy] for 𝑑 ∈ 1:nrow(df_portfolio)])
cf_λ_eoy_one =
  -sum([liab_ins.mps[𝑑].λ[1,:eoy] *
          (1 + liab_ins.mps[𝑑].λ[1,:infl])
        for 𝑑 ∈ 1:nrow(df_portfolio)]) -
  invs.igs[:IGCash].mv_0 *
  (1 + (cf_prem_one + cf_λ_boy_one) / invs.mv_0) *
  invs.igs[:IGCash].cost.rel[1] *
  (1 + invs.igs[:IGCash].cost.infl_rel[1]) -
  invs.igs[:IGStock].mv_0 *
  (1 + (cf_prem_one + cf_λ_boy_one) / invs.mv_0) *
  invs.igs[:IGStock].cost.rel[1] *
  (1 + invs.igs[:IGStock].cost.infl_rel[1]) -
  invs.igs[:IGCash].cost.abs[1] *
  (1 + invs.igs[:IGCash].cost.infl_abs[1]) -
  invs.igs[:IGStock].cost.abs[1] *
  (1 + invs.igs[:IGStock].cost.infl_abs[1])
cf_qx_one = -sum([qx_one[𝑑] *liab_ins.mps[𝑑].β[1,:qx]
                  for 𝑑 ∈ 1:nrow(df_portfolio)])
cf_sx_one = -sum([sx_one[𝑑] *liab_ins.mps[𝑑].β[1,:sx]
                  for 𝑑 ∈ 1:nrow(df_portfolio)])
cf_px_one = -sum([px_one[𝑑] *liab_ins.mps[𝑑].β[1,:px]
                  for 𝑑 ∈ 1:nrow(df_portfolio)])
cf_bonus_one =
  -sum([t_bonus_quota[1] * liab_ins.mps[𝑑].tpg_price_0
        for 𝑑 ∈ 1:5])
cf_invest_one =
  (invs.mv_0+cf_prem_one + cf_λ_boy_one) * y_invest[1]

@test cf_prem_one ≈ ins_sum * sum(df_portfolio[:,:n]) *
                    prem_price_ratio
@test cf_qx_one ≈ -sum([qx_one[𝑑] * df_portfolio[𝑑,:n] * ins_sum
                        for 𝑑 ∈ 1:nrow(df_portfolio)])
@test cf_sx_one ≈ -sum([sx_one[𝑑] * sx_fac * df_portfolio[𝑑,:n] *
                        (T - 𝑑 +1) *  ins_sum * prem_price_ratio
                        for 𝑑 ∈ 1:nrow(df_portfolio)])
@test cf_px_one ≈ -px_one[1] * df_portfolio[1,:n] *  ins_sum
@test cf_bonus_one ≈ proj.cf[1, :bonus]
@test cf_prem_one ≈ proj.cf[t, :prem]
@test cf_λ_boy_one ≈ proj.cf[t, :λ_boy]
@test cf_λ_eoy_one ≈ proj.cf[t, :λ_eoy]
@test cf_qx_one ≈ proj.cf[t, :qx]
@test cf_sx_one ≈ proj.cf[t, :sx]
@test cf_px_one ≈ proj.cf[t, :px]
@test cf_invest_one ≈ proj.cf[t, :invest]
@test cf_l_other_total[1] ≈ proj.cf[t, :l_other]


## technical provisions for guaranteed benefits -----------------

## the following is used in the text
@test(abs(δ_sx_one[1]-1) > eps(1.) ? true : false)

probabs = Array{DataFrame}(undef, nrow(df_portfolio))
for 𝑑 ∈ 1:nrow(df_portfolio)
  probabs[𝑑] = deepcopy(prob_be)
  probabs[𝑑][:sx] =
    δ_sx_one[𝑑] * convert(Array, probabs[𝑑][:sx]) *
    df_portfolio[𝑑, :sx_be_fac]
  probabs[𝑑][:px] = 1 .- probabs[𝑑][:qx] - probabs[𝑑][:sx]
end

## We recalculate technical provisions with updated sx
for 𝑑 ∈ 1:nrow(df_portfolio)
  tp[𝑑] = zeros(Float64, T)
  local τ = t_0 - df_portfolio[𝑑, :t_start]
  for 𝑡 ∈ (T-1-τ):-1:(1)
    tp[𝑑][𝑡] = tpberec(tp[𝑑][𝑡 + 1], 𝑡, τ, probabs[𝑑][:sx])
  end
end

tpg_0_1_1 =
  sum([probabs[𝑑][T-𝑑+1, :px] * tp[𝑑][1] *
         df_portfolio[𝑑, :n]
       for 𝑑 ∈ 1:nrow(df_portfolio)])

@test tpg_0_1_1 ≈ proj.val[1,:tpg]
@test proj.val[1,:tpg]-proj.val_0[1,:tpg] ≈ -proj.cf[1,:Δtpg]

# Profit and tax ------------------------------------------------
@test sum(convert(Array, proj.cf[1, [:prem, :λ_boy, :λ_eoy, :qx,
                                     :sx, :px, :invest, :Δtpg, :l_other, :bonus]])) ≈
      proj.cf[1, :profit]

tax_pre = zeros(Float64, T)
tax= zeros(Float64, T)
tax_credit = tax_credit_0
tax_credit_vec = zeros(Float64, T)

for 𝑡 ∈ 1:T
  tax_pre[𝑡] = tax_rate * proj.cf[𝑡,:profit]
  if tax_credit > tax_pre[𝑡]
    tax[𝑡] = 0
    global tax_credit -= tax_pre[𝑡]
  else
    tax[𝑡] = tax_pre[𝑡] - tax_credit
    global tax_credit = 0
  end
  tax_credit_vec[𝑡] = tax_credit
end

@test tax ≈ -proj.cf[:,:tax]

## Dividends  ----------------------------------------------------
surp_quota = zeros(Float64,T)
for 𝑡 ∈ 1:T
  surp_quota[𝑡] =
    proj.val[𝑡, :invest] /
    (proj.val[𝑡, :tpg] + proj.val[𝑡, :l_other]) - 1
end

invest_eoy_prev =
  Float64[𝑡 == 1 ?
            proj.val_0[𝑡, :invest] :
            proj.val[𝑡-1, :invest] for 𝑡 ∈ 1:T]
invest_boy =
  convert(Array,
          invest_eoy_prev + proj.cf[:prem] + proj.cf[:λ_boy])
invest_eoy_pre_divid =
  invest_eoy_prev + proj.cf[:profit] + proj.cf[:tax] -
  proj.cf[:Δtpg] + proj.cf[:gc]

@test invest_boy ≈ invs.mv_boy
@test invest_eoy_pre_divid ≈
      Float64[VORMI.investpredivid(𝑡, invs, proj) for 𝑡 ∈ 1:T]

val_liab = convert(Array, proj.val[:tpg] .- proj.val[:l_other])
q_surp =
  ((invest_eoy_pre_divid .- proj.val[:tpg] .-
    proj.val[:l_other]) ./
  (proj.val[:tpg] + proj.val[:l_other]))

## The following was used in the text:
@test q_surp[1] > dyn.quota_surp
@test  min.(0, convert(Array,
              (1+dyn.quota_surp) * ( proj.val[:tpg] +
                                    proj.val[:l_other])-
                                    invest_eoy_pre_divid)) ≈
      proj.cf[:divid]

## Dividend mechanism works:
for 𝑡 ∈ 1:T
  if (proj.cf[𝑡, :divid] < 0) &
      (proj.val[𝑡, :tpg] + proj.val[𝑡, :l_other] > 0)
    @test dyn.quota_surp ≈
          (proj.val[𝑡, :invest] - proj.val[𝑡, :tpg] -
            proj.val[𝑡, :l_other]) /
          (proj.val[𝑡, :tpg] + proj.val[𝑡, :l_other])
  end
  if proj.cf[t, :divid] ≥ 0
    @test proj.cf[t, :divid] ≈ 0
  end
end

@test proj.val[1, :invest] ≈
      invest_eoy_pre_divid[1] + proj.cf[1, :divid]

## Balance sheet for ≥ 0 ========================================

fdb = zeros(Float64, T)
for 𝑡 ∈ (T-1):-1:1
  fdb[𝑡] =
    (fdb[𝑡 + 1] -  proj.cf[𝑡 + 1, :bonus]) /
    (1 .+ rfr[𝑡 + 1])
end
fdb_0 =
  (fdb[1] -  proj.cf[1, :bonus]) /  (1 .+ rfr[1])

@test -cumprod(1 ./ (1 .+ rfr)) ⋅ proj.cf[:bonus] ≈
      proj.val_0[1,:bonus]
@test fdb_0 ≈ proj.val_0[1,:bonus]
@test fdb ≈ proj.val[:bonus]

balance = vcat(proj.val_0, proj.val)
## here reserves for boni are considered part of capital.
@test balance[:surplus] ≈
      balance[:invest] - balance[:tpg] - balance[:l_other]

## recall that balance[t, :] = proj.val[t-1, :] for t>1
for 𝑡 ∈ 2:(T+1)
  for 𝑤 ∈ [:invest, :tpg, :l_other, :surplus, :bonus, :cost_prov]
     @test balance[𝑡, 𝑤] ≈ proj.val[𝑡-1, 𝑤]
  end
end

## technical provisions for absolute costs & investment costs ---

# provisions absolute costs & investment costs are correct:
for 𝜏 ∈ 1:5
  x = balance[𝜏, :cost_prov]
  for 𝑡 ∈ 𝜏:T
    x *= (1 + rfr[𝑡])
    x -= sum(convert(Array,
                     balance[𝑡,
                             [:tpg, :bonus,
                              :l_other, :cost_prov]])) *
      invs.igs[:IGCash].cost.cum_infl_rel[𝑡] *
      invs.igs[:IGCash].cost.rel[𝑡]
    x -= proj.fixed_cost_gc[𝑡]
  end
  @test x ≈ 0 atol=1.0e-14
end


tpgprev(tp_next, t) =
  (tp_next + cost_abs[t + 1])/(1 + rfr[t + 1])

tp_cost_abs = zeros(Float64, T)
for 𝑡 ∈ (T-1):-1:1
  tp_cost_abs[𝑡] = tpgprev(tp_cost_abs[𝑡 + 1], 𝑡)
end
tp_cost_abs_0 = tpgprev(tp_cost_abs[1], 0)

@test [tp_cost_abs_0; tp_cost_abs] ≈
      Float64[VORMI.tpgfixed(𝑡, cap_mkt.rfr.x[1:liab_ins.dur],
                             proj.fixed_cost_gc)
              for 𝑡 ∈ 0:T]

## S2 Example ###################################################

liabs_mod_0 = balance[1,:tpg] +balance[1,:bonus] + balance[1, :cost_prov]
assets_mod_0 = balance[1,:invest] + proj.tax_credit_0
bof_0 = assets_mod_0 - liabs_mod_0
symb_bal = [:invest, :tpg, :l_other, :surplus, :bonus]
@test convert(Array, balance[1,symb_bal]) ≈
      convert(Array, s2.balance[1, symb_bal])
@test VORMI.bof(s2, :be) ≈ bof_0

## S2 Example Interest ------------------------------------------

ind_mkt = findfirst( (in)([:S2Mkt]), ds2[:mdl])
ind_mkt_int = findfirst( (in)([:S2MktInt]), ds2_mkt[:mdl])
s2_mkt_int = s2.mds[ind_mkt].mds[ind_mkt_int]
rfr_up = VORMI.rfrshock(cap_mkt.rfr.x, s2_mkt_int, :spot_up)
rfr_down = VORMI.rfrshock(cap_mkt.rfr.x, s2_mkt_int, :spot_down)

@test rfr ≈ VORMI.spot2forw(VORMI.forw2spot(rfr))
@test rfr_down ≈ VORMI.spot2forw(VORMI.forw2spot(rfr) .*
                 (1 .+ ds2_mkt_int[:shock][:spot_down][1:T]))
@test rfr_up ≈ VORMI.spot2forw(
                   VORMI.forw2spot(rfr) .+
                  max.(ds2_mkt_int[:spot_up_abs_min],
                      VORMI.forw2spot(rfr) .*
                      ds2_mkt_int[:shock][:spot_up][1:T]))

## S2 Example Equity --------------------------------------------
ind_mkt = findfirst( (in)([:S2Mkt]), ds2[:mdl])
ind_mkt_eq = findfirst( (in)([:S2MktEq]), ds2_mkt[:mdl])
s2_mkt_eq = s2.mds[ind_mkt].mds[ind_mkt_eq]
bal = s2_mkt_eq.balance

@test bal[bal[:scen] .== :type_1,:invest][1] ≈
      (1 + eq_shock[:type_1]) * sum(df_stock[:mv_0]) + sum(df_cash[:mv_0])

## S2 Example Market risk----------------------------------------
ind_mkt = findfirst( (in)([:S2Mkt]), ds2[:mdl])
s2_mkt = s2.mds[ind_mkt]
@test s2_mkt_int.scen_up == false
corr_mkt = s2_mkt.corr_down[1:2,1:2]
scr_mkt_net = [s2_mkt_int.scr[NET], s2_mkt_eq.scr[NET]]
scr_mkt_gross = [s2_mkt_int.scr[GROSS], s2_mkt_eq.scr[GROSS]]
@test sqrt(scr_mkt_net ⋅ (corr_mkt * scr_mkt_net)) ≈
      s2_mkt.scr[NET]
@test sqrt(scr_mkt_gross ⋅ (corr_mkt * scr_mkt_gross)) ≈
      s2_mkt.scr[GROSS]

## Default Risk type 1 -----------------------------------------
ind_def = findfirst( (in)([:S2Def]), ds2[:mdl])
s2_def = s2.mds[ind_def]
inv_len = length(invs.igs[:IGCash].investments)
@test inv_len == 2

accs_mv_0 =
  Float64[invs.igs[:IGCash].investments[𝑖].mv_0
          for 𝑖 ∈ 1:inv_len]
accs_cqs =
  Int[parse(Int, string(string(invs.igs[:IGCash].
                                 investments[𝑖].cqs)[end]))
      for 𝑖 ∈ 1:inv_len]
accs_tlgd =
  Float64[s2_def.mds[1].tlgd[accs_cqs[𝑖]+1] for 𝑖 ∈ 1:inv_len]
accs_slgd =
  Float64[s2_def.mds[1].slgd[accs_cqs[𝑖]+1] for 𝑖 ∈ 1:inv_len]
accs_defu =
  Float64[s2_def.mds[1].u[accs_cqs[𝑖]+1,accs_cqs[𝑗]+1]
          for 𝑖 ∈ 1:inv_len, 𝑗 ∈ 1:inv_len]
accs_defv =
  Float64[s2_def.mds[1].v[accs_cqs[𝑖]+1]
          for 𝑖 ∈ 1:inv_len]

accs_var_t = accs_tlgd ⋅ (accs_defu * accs_tlgd)
accs_var_s = accs_slgd ⋅ accs_defv
accs_var = accs_var_t + accs_var_s
accs_sigma_norm = sqrt(accs_var) / sum(accs_tlgd)
accs_scr_low = s2.mds[ind_def].mds[1].scr_par[:low][1]
accs_scr_low_fac = s2.mds[ind_def].mds[1].scr_par[:low][2]
accs_scr_def = accs_scr_low_fac * sqrt(accs_var)

@test s2_def.scr[NET] ≈ accs_scr_def
@test s2_def.scr[GROSS] ≈ accs_scr_def

## Life mortality -----------------------------------------------
ind_life = findfirst( (in)([:S2Life]), ds2[:mdl])
ind_life_qx = 1
s2_life_qx = s2.mds[ind_life].mds[ind_life_qx]

@test collect(keys(s2_life_qx.shock))[1] == :qx
@test s2_life_qx.shock[:qx] > 0
@test ! s2_life_qx.mp_select[:qx][1]
for 𝑖 ∈ 2:length(s2_life_qx.mp_select[:qx])
  @test s2_life_qx.mp_select[:qx][𝑖]
end

## Life longevity -----------------------------------------------

ind_life_px = 2
s2_life_px = s2.mds[ind_life].mds[ind_life_px]
@test collect(keys(s2_life_px.shock))[1] == :px
@test s2_life_px.shock[:px] < 0
for 𝑖 ∈ 2:length(s2_life_px.mp_select[:px])
  @test !s2_life_px.mp_select[:px][𝑖]
end

## Life surrender -----------------------------------------------

ind_life_sx = 4
s2_life_sx = s2.mds[ind_life].mds[ind_life_sx]

@test (sort(collect(keys(s2_life_sx.shock))) ==
         sort([:sx_down, :sx_up,
               :sx_mass_other, :sx_mass_pension]))

for 𝑚 ∈ 2: length(s2_life_sx.mp_select[:sx_down])
  @test ! s2_life_sx.mp_select[:sx_down][𝑚]
end
for 𝑚 ∈ 2:length(s2_life_sx.mp_select[:sx_up])
  @test s2_life_sx.mp_select[:sx_up][𝑚]
end
for 𝑚 ∈ 2:length(s2_life_sx.mp_select[:sx_mass_other])
  @test s2_life_sx.mp_select[:sx_mass_other][𝑚]
end

## Life cost ----------------------------------------------------

ind_life_cost = 5
s2_life_cost = s2.mds[ind_life].mds[ind_life_cost]
@test collect(keys(s2_life_cost.shock)) == [:cost]

## Life cat -----------------------------------------------------
s2.mds[ind_life].mds
ind_life_cat = 7
s2_life_cat = s2.mds[ind_life].mds[ind_life_cat]
@test collect(keys(s2_life_cat.shock)) == [:cat]
for 𝑚 ∈ 2:length(s2_life_cat.mp_select[:cat])
  @test s2_life_cat.mp_select[:cat][𝑚]
end

## Life aggregation ---------------------------------------------

s2_life = s2.mds[ind_life]

ind_life_risks =
  [ind_life_qx, ind_life_sx, ind_life_cost, ind_life_cat]
life_corr = s2_life.corr[ind_life_risks, ind_life_risks]

scrs_life_net = [s2_life_qx.scr[NET],
                 s2_life_sx.scr[NET],
                 s2_life_cost.scr[NET],
                 s2_life_cat.scr[NET]]
scrs_life = [s2_life_qx.scr[GROSS],
             s2_life_sx.scr[GROSS],
             s2_life_cost.scr[GROSS],
             s2_life_cat.scr[GROSS]]

@test sqrt(scrs_life ⋅ (life_corr * scrs_life)) ≈
      s2_life.scr[GROSS]
@test sqrt(scrs_life_net ⋅ (life_corr * scrs_life_net)) ≈
      s2_life.scr[NET]

## BSCR =========================================================

ind = [ind_mkt, ind_def, ind_life]

bscr_corr = ds2[:corr][ind, ind]
bscrs_gross =
  [s2_mkt.scr[GROSS], s2_def.scr[GROSS], s2_life.scr[GROSS]]

bscrs_net = [s2_mkt.scr[NET], s2_def.scr[NET], s2_life.scr[NET]]

@test sqrt(bscrs_net ⋅ (bscr_corr * bscrs_net)) ≈ s2.bscr[NET]
@test sqrt(bscrs_gross ⋅ (bscr_corr * bscrs_gross)) ≈
      s2.bscr[GROSS]

## operational risk =============================================
@test s2.op.comp_tp ≈
      (proj.val_0[1, :tpg] + proj.val_0[1, :bonus]) *
      s2.op.fac[:tp]

@test s2.op.comp_prem ≈
      s2.op.fac[:prem] * s2.op.prem_earned + s2.op.fac[:prem] *
        max(0, s2.op.prem_earned -
               s2.op.fac[:prem_py] * s2.op.prem_earned_prev)

## Adjustments ==================================================
## Adj technical provisions -------------------------------------
@test -max(0.0, min(s2.bscr[GROSS] - s2.bscr[NET],
                    VORMI.fdb(s2, :be))) ≈
      s2.adj_tp
@test s2.adj_dt == 0
@test s2.liabs_mod ≈
       s2.balance[1,:tpg] + s2.balance[1,:bonus] +  s2.balance[1,:cost_prov]
@test s2.invest_mod ≈ s2.balance[1,:invest]

ds2[:coc]

coc = 0.06
balance = vcat(proj.val_0, proj.val)
length(balance)
tpbe =
  convert(Array,
          balance[:tpg] + balance[:bonus] + balance[:cost_prov])
src_future = (tpbe * s2.scr / tpbe[1])[1:T]
discount = 1 ./ cumprod(1 .+ rfr)
risk_margin = coc * src_future ⋅ discount

@test s2.risk_margin ≈ risk_margin

@test s2.scr_ratio ≈
      (s2.invest_mod - s2.liabs_mod - s2.risk_margin) / s2.scr
@test s2.scr_ratio > 1

#################################################################
println("End S2Life test")

sqrt
