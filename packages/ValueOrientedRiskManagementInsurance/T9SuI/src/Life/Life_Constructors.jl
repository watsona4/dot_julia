
## assets -------------------------------------------------------
function IGCost(df_cost)
  IGCost(df_cost[:, :rel],
         df_cost[:, :abs],
         df_cost[:, :infl_rel],
         df_cost[:, :infl_abs],
         cumprod(1 .+ df_cost[:, :infl_rel]),
         cumprod(1 .+ df_cost[:, :infl_abs]),
         zeros(Float64, nrow(df_cost))
         )
end

function IGStock(cap_mkt::CapMkt, mv_0, alloc, cost)
  investments = Array{InvestStock}(undef, 0)
  for 𝑖 ∈ 1:length(alloc.name)
    push!(investments,
          InvestStock(alloc.name[𝑖],
                      cap_mkt.stock,
                      mv_0 * alloc.total[1] * alloc.all[1,𝑖],
                      zeros(Float64, size(alloc.all, 1))))
  end
  IGStock(investments, mv_0 * alloc.total[1],
          zeros(Float64, size(alloc.all, 1)), alloc,
          deepcopy(cost))
end

function IGCash(cap_mkt::CapMkt, mv_0, alloc, cost)
  investments = Array{InvestCash}(undef, 0)
  for 𝑖 ∈ 1:length(alloc.name)
    push!(investments,
          InvestCash(alloc.name[𝑖],
                     cap_mkt.rfr,
                     mv_0 * alloc.total[1] * alloc.all[1,𝑖],
                     zeros(Float64, size(alloc.all, 1)),
                     alloc.lgd[𝑖],
                     alloc.cqs[𝑖]))
  end
  IGCash(investments, mv_0 * alloc.total[1],
         zeros(Float64, size(alloc.all, 1)), alloc,
         deepcopy(cost))
end

function InvPort(t_0,
                 dur,
                 cap_mkt::CapMkt,
                 mv_0,
                 allocs::Dict{Symbol, Alloc},
                 costs::Dict{Symbol, DataFrame}
                 )
  igs = Dict{Symbol, InvestGroup}()
  for 𝑖𝑔_𝑠𝑦𝑚𝑏 ∈ collect(keys(allocs))
    ## ig_symb are the symbols corresponding to the
    ## types of investment groups: :IGCash, IGStock
    merge!(igs,
           Dict(𝑖𝑔_𝑠𝑦𝑚𝑏 => eval(𝑖𝑔_𝑠𝑦𝑚𝑏)(cap_mkt,
                                        mv_0,
                                        allocs[𝑖𝑔_𝑠𝑦𝑚𝑏],
                                        IGCost(costs[𝑖𝑔_𝑠𝑦𝑚𝑏])
                                         )))
  end
  return(InvPort(t_0,                  ## start of projection
                 mv_0,                 ## init. mv pre prem..
                 zeros(Float64, dur),  ## mv bop post prem...
                 zeros(Float64, dur),  ## mv eop
                 zeros(Float64, dur),  ## average yield
                 zeros(Float64, dur),  ## investment costs
                 igs))                 ## investment groups
end

## insurance liabilities ----------------------------------------
function Product(rfr_price, prob_price, β_in, λ_price)
  dur = nrow(β_in)
  prob = deepcopy(prob_price)
  prob[:px] = 1 .- prob[:qx] - prob[:sx]
  λ_price[:cum_infl] = cumprod(1 .+ λ_price[:infl])
  return Product(dur, rfr_price, prob, β_in, λ_price,
                 premium(1, rfr_price, prob, β_in, λ_price))
end

function ModelPoint(n, t_0, t_start,
                    prob_be, sx_be_fac, λ_be,
                    cost_infl,
                    hypo_bonus_rate, product, ins_sum,
                    pension_contract)
  ## Time model for model point: See documentation of type
  s_0 = t_0 - t_start
  dur = product.dur - s_0
  s_future = (s_0 + 1):product.dur
  prob = deepcopy(prob_be)[s_future, :]
  prob[:sx] *= sx_be_fac
  prob[:px] = 1 .- prob[:qx] - prob[:sx]
  lx_boy = zeros(Float64, dur)
  β = DataFrame()
  for 𝑛𝑎𝑚𝑒 ∈ names(product.β)
    β[𝑛𝑎𝑚𝑒] = n * ins_sum * product.β[s_future, 𝑛𝑎𝑚𝑒]
  end
  β[:prem] *= product.prem_norm
  β[:sx] *= product.prem_norm

  λ = deepcopy(λ_be)[s_future, :]
  λ[:boy] *= n * ins_sum
  λ[:eoy] *= n * ins_sum
  ## be cost inflation input relates to t_0 not s_0:
  λ[:infl] = deepcopy(cost_infl)
  λ[:cum_infl] = cumprod(1 .+ λ[:infl])
  λ_price = deepcopy(product.λ)[s_future, :]
  λ_price[:boy] *= n * ins_sum
  λ_price[:eoy] *= n * ins_sum
  λ_price[:cum_infl] = cumprod(1 .+ product.λ[:infl])[s_future]
  rfr_price_0 = product.rfr[s_0 == 0 ? 1 : s_0]
  rfr_price = product.rfr[s_future]
  tpg_price_0 = tpg(0,
                    rfr_price,
                    product.prob[s_future, :],
                    β,
                    λ_price)
  tpg_price = zeros(Float64, dur)
  for 𝑡 ∈ 1:dur
    tpg_price[𝑡] = tpg(𝑡,
                       rfr_price,
                       product.prob[s_future, :],
                       β,
                       λ_price)
  end
  return ModelPoint(n, t_start, dur, prob, lx_boy, 0.0,
                    β, λ,  hypo_bonus_rate,
                    rfr_price_0, rfr_price,
                    tpg_price_0, tpg_price,
                    ones(Float64, dur),
                    pension_contract)
end

function LiabIns(t_0::Int, prob_be, λ_be,
                 cost_infl, product, df_port)
  n = nrow(df_port)
  mps = Array{ModelPoint}(undef, 0)
  dur = 0
  for 𝑑 ∈ 1:n
    push!(mps, ModelPoint(df_port[𝑑, :n],
                          t_0,
                          df_port[𝑑, :t_start],
                          prob_be,
                          df_port[𝑑, :sx_be_fac],
                          λ_be,
                          cost_infl[𝑑],
                          df_port[𝑑, :bonus_rate_hypo],
                          product,
                          df_port[𝑑, :ins_sum],
                          df_port[𝑑, :pension_contract]))
    dur = max(dur, mps[𝑑].dur)
  end
  gc = zeros(Float64, dur)
  for 𝑚𝑝 ∈ mps
    𝑚𝑝.gc = zeros(Float64, dur)
    𝑚𝑝.gc[1:𝑚𝑝.dur] +=
      vcat(1, cumprod(𝑚𝑝.prob[1:(𝑚𝑝.dur-1), :px]))
    gc +=  𝑚𝑝.n * 𝑚𝑝.gc
  end
  gc /= gc[1]
  Δgc = diff(vcat(gc, 0))
  return LiabIns(n, t_0, dur, mps, gc, Δgc)
end

## other liabilities --------------------------------------------
function Debt(t_0, t_debt_0, t_debt_mat,
              name::Symbol, nominal, coupon)
  name = name
  τ_debt_0 = t_debt_0 - t_0
  dur_debt = t_debt_mat - t_debt_0 + 1
  τ_mat = dur_debt + τ_debt_0 - 1
  Debt(name, t_debt_0, t_debt_mat, τ_debt_0, τ_mat, nominal, coupon)
end

function Debt(t_0, df_debt::DataFrame)
  name = df_debt[1, :name]
  t_init = df_debt[1, :t_init]
  t_mat = df_debt[1, :t_mat]
  τ_init = t_init - t_0
  dur = t_mat - t_init + 1
  τ_mat = dur + τ_init - 1
  Debt(name, t_init, t_mat, τ_init, τ_mat,
       df_debt[1, :nominal], df_debt[1, :coupon])
end

function LiabOther(t_0, df_debts::DataFrame)
  subord = Array{Debt}(undef, nrow(df_debts))
  for 𝑑 ∈ 1:nrow(df_debts)
    subord[𝑑] = Debt(t_0, df_debts[𝑑,:])
  end
  return LiabOther(subord)
end

## dynamics -----------------------------------------------------
function Dynamic(dur, bonus_factor, quota_surp::Float64)
  Dynamic(bonus_factor,
          quota_surp,
          zeros(Float64, dur))
end

## cashflow projection ------------------------------------------
function Projection(liabs, tax_rate, tax_credit_0)
  t_0 = liabs.t_0
  dur = liabs.dur
  cf = DataFrame(
    qx = zeros(Float64, dur),
    sx = zeros(Float64, dur),
    px = zeros(Float64, dur),
    prem = zeros(Float64, dur),
    λ_boy = zeros(Float64, dur),
    λ_eoy = zeros(Float64, dur),
    bonus = zeros(Float64, dur),
    invest = zeros(Float64, dur),
    new_debt = zeros(Float64, dur),
    l_other = zeros(Float64, dur),
    profit = zeros(Float64, dur),
    tax = zeros(Float64, dur),
    divid = zeros(Float64, dur),
    gc = zeros(Float64, dur),        ## not affecting profit/loss
    Δtpg = zeros(Float64, dur),      ## not real cf, affects p/l
    cost_prov = zeros(Float64, dur)  ## for the cost provisions
    )
  val = DataFrame(
    invest = zeros(Float64, dur),
    tpg = zeros(Float64, dur),
    l_other = zeros(Float64, dur),
    surplus = zeros(Float64, dur),
    bonus = zeros(Float64, dur),
    cost_prov = zeros(Float64, dur)      ## cost provisions
    )
  val_0 = deepcopy(val[1, :])
  return Projection(t_0, dur, cf, val_0, val,
                    tax_rate,
                    tax_credit_0,
                    zeros(Float64, dur),
                    zeros(Float64, dur))
end

function Projection(tax_rate,
                    tax_credit_0,
                    cap_mkt::CapMkt,
                    invs::InvPort,
                    liabs::LiabIns,
                    liabs_other::LiabOther,
                    dyn::Dynamic)
  proj = Projection(liabs, tax_rate, tax_credit_0)
  for 𝑡 ∈ 1:liabs.dur
    for 𝑖𝑔 ∈ [:IGCash, :IGStock]
      proj.fixed_cost_gc[𝑡] +=
        invs.igs[𝑖𝑔].cost.abs[𝑡] *
        invs.igs[𝑖𝑔].cost.cum_infl_abs[𝑡] *
        liabs.gc[𝑡]
    end
  end
  l_other = deepcopy(liabs_other)
  goingconcern!(l_other, liabs.Δgc)
  val0!(cap_mkt, invs, liabs, l_other, proj)
  proj.cf[:,:gc] = liabs.Δgc * (proj.val_0[1,:invest] -
                                  proj.val_0[1,:tpg] -
                                  proj.val_0[1,:l_other])
  for 𝑡 = 1:liabs.dur
    project!(𝑡, cap_mkt, invs, liabs, l_other, dyn, proj)
  end
  valbonus!(cap_mkt.rfr.x, proj)
  valcostprov!(cap_mkt.rfr.x, invs, proj)
  return proj
end
