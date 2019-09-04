function s2riskmargin(p::ProjParam, scr, coc)
  invs = InvPort(p.t_0, p.T, p.cap_mkt, p.invs_par...)
  proj = Projection(p.tax_rate, p.tax_credit_0, p.cap_mkt, invs,
                    p.l_ins, p.l_other, p.dyn)
  bal_vec  = vcat(proj.val_0, proj.val)
  discount = 1 ./ cumprod(1 .+ p.cap_mkt.rfr.x)
  tp = convert(Array, bal_vec[:tpg] +
                      bal_vec[:bonus] +
                      bal_vec[:cost_prov])[1:(p.T-p.t_0)]
  src_future = (tp * scr / tp[1])
  coc * src_future ⋅ discount
end

"""
`s2bal(p::ProjParam)`

Calculation of the unshocked S2 balance sheet
"""
function s2bal(p::ProjParam)
  invs = InvPort(p.t_0, p.T, p.cap_mkt, p.invs_par...)
  proj = Projection(p.tax_rate, p.tax_credit_0, p.cap_mkt, invs,
                    p.l_ins, p.l_other, p.dyn)
  bal =
    hcat(proj.val_0, DataFrame(tax_credit = proj.tax_credit_0))
  return hcat(bal, DataFrame(bof = bof(bal), scen = :be))
end

"""
`s2bal(p::ProjParam, md::S2Module, shock!::Any, scen::Symbol)`

Calculation of the shocked S2 balance sheet for module `md`
"""
function s2bal(p::ProjParam,
               md::S2Module,
               shock!::Any,
               scen::Symbol)
  cpm = deepcopy(p.cap_mkt)
  l_ins = deepcopy(p.l_ins)
  if md.shock_object ==  :CapMkt shock!(cpm, md) end
  invs = InvPort(p.t_0, p.T, cpm, p.invs_par...)
  if md.shock_object == :CapMkt_AdjVal0 shock!(invs, md) end
  if md.shock_object == :LiabIns shock!(l_ins, md) end
  if md.shock_object == :InvPort_LiabIns
    shock!(invs, l_ins, md)
  end
  proj = Projection(p.tax_rate, p.tax_credit_0, cpm, invs,
                    l_ins, p.l_other, p.dyn)
  if md.shock_object == :CapMkt_AdjVal0
    mkt_val0_adj!(proj, invs, md, scen)
  end
  bal =
    hcat(proj.val_0, DataFrame(tax_credit = proj.tax_credit_0))
  return hcat(bal, DataFrame(bof = bof(bal), scen = scen))
end

"""
`bof(bal::DataFrame)`

Helper function for the calculation of basic own funds
"""
bof(bal::DataFrame) =
  bal[1, :invest][1,1] +
  bal[1, :tax_credit][1,1] -
  bal[1, :tpg][1,1] -
  bal[1, :cost_prov][1,1] -
  bal[1, :bonus][1,1]

"""
`bof(md::S2Module, scen::Symbol)`

Basic own funds for module `md` and scenario `scen`
"""
bof(md::S2Module, scen::Symbol) =
  bof(md.balance[md.balance[:scen] .== scen, :])

"""
`fdb(md::S2Module, scen::Symbol)`

Future discretionary benefits for module `md` and scenario `scen`
"""
fdb(md::S2Module, scen::Symbol) =
  md.balance[md.balance[:scen] .== scen, :bonus][1,1]

"""
`scr!(mdl::S2Module)`

Scenario based SCR calculation for `mdl::S2Module`

**Changed:** `mdl::S2Module`
"""
function scr!(mdl::S2Module)
  shock_keys = collect(keys(mdl.shock))
  net =
    (bof(mdl, :be) .- Float64[bof(mdl, 𝑠𝑚) for 𝑠𝑚 ∈ shock_keys])
  gross =
    (net .+ fdb(mdl, :be) .-
     Float64[fdb(mdl, 𝑠𝑚) for 𝑠𝑚 ∈ shock_keys])
  if :corr in fieldnames(typeof(mdl))
    mdl.scr[NET] = sqrt(net ⋅ (mdl.corr * net))
    mdl.scr[GROSS] = sqrt(gross ⋅ (mdl.corr * gross))
  else
    i = findmax(net)[2]
    mdl.scr[NET] = max(0, net[i])
    mdl.scr[GROSS] = max(0, gross[i])
  end
end

"""
`scr(md::S2Module, corr::Matrix{Float64})`

Aggregation of SCRs of sub-modules
"""
function scr(md::S2Module, corr::Matrix{Float64})
  _scr = zeros(Float64, 2)
  net = Float64[md.mds[𝑖].scr[NET] for 𝑖 ∈ 1:length(md.mds)]
  gross = Float64[md.mds[𝑖].scr[GROSS] for 𝑖 ∈ 1:length(md.mds)]
  _scr[GROSS] = sqrt(gross ⋅ (corr * gross))
  _scr[NET] = sqrt(net ⋅ (corr * net))
  return _scr
end

## S2MktInt -----------------------------------------------------
"""
`scr!(mkt_int::S2MktInt)`

SCR for interest rate risk, sub-module `mkt_int`

**Changed:** `mkt_int::S2MktInt`
"""
function scr!(mkt_int::S2MktInt)
  shock_keys = collect(keys(mkt_int.shock))
  net =
    bof(mkt_int, :be) .-
  Float64[bof(mkt_int, 𝑠𝑚) for 𝑠𝑚 ∈ shock_keys]
  gross =
    net .+ fdb(mkt_int, :be) -
    Float64[fdb(mkt_int, 𝑠𝑚) for 𝑠𝑚 ∈ shock_keys]

  i_up = findfirst( (in)([:spot_up]), shock_keys)
  i_down = findfirst( (in)([:spot_down]), shock_keys)

  mkt_int.scen_up = net[i_up] >= net[i_down]
  mkt_int.scr[NET] = maximum([0.0; net])
  mkt_int.scr[GROSS] =
    max(0.0, mkt_int.scen_up ? gross[i_up] : gross[i_down])
end

"""
`rfrshock(rfr::Vector{Float64}, s2_mkt_int, int_type)`

Helper function: shock for the risk free interest rate
"""
function rfrshock(rfr::Vector{Float64}, s2_mkt_int, int_type)
  ## shock the risk free interest rate
  len = min(length(rfr),
            length(s2_mkt_int.shock[:spot_up]),
            length(s2_mkt_int.shock[:spot_down]))
  spot = forw2spot(rfr[1:len])
  if int_type == :spot_down
    forw =
      spot2forw(spot .*
                (1 .+ s2_mkt_int.shock[:spot_down][1:len]))
  elseif int_type == :spot_up
    forw =
      spot2forw(spot .+
                max.(spot .* s2_mkt_int.shock[:spot_up][1:len],
                    s2_mkt_int.spot_up_abs_min))
  else # :be
      forw = spot2forw(spot)
  end
  return forw
end

"""
`mktintshock!(cap_mkt::CapMkt, s2_mkt_int, int_type::Symbol)`

Shock for interest rate market risk

**Changed:** `cap_mkt::CapMkt`
"""
function mktintshock!(cap_mkt::CapMkt,
                      s2_mkt_int,
                      int_type::Symbol)
  cap_mkt.rfr.x =
    deepcopy(rfrshock(cap_mkt.rfr.x, s2_mkt_int, int_type))
end



## S2MktEq ------------------------------------------------------
"""
`mkteqshock!(invs::InvPort, mkt_eq, eq_type::Symbol)`

Shock for equity market risk

**Changed:** `invs::InvPort`
"""
function mkteqshock!(invs::InvPort, mkt_eq, eq_type::Symbol)
  for 𝑖𝑛𝑣𝑒𝑠𝑡 ∈ invs.igs[:IGStock].investments
    if mkt_eq.eq2type[𝑖𝑛𝑣𝑒𝑠𝑡.name] == eq_type
      𝑖𝑛𝑣𝑒𝑠𝑡.proc.x *= (1 + mkt_eq.shock[eq_type])
    end
  end
end

"""
`mkt_val0_adj!(proj::Projection, invs::InvPort,
               mkt_eq, eq_type::Symbol)`

Adjust initial market value for S2 balance sheet in order to
reflect that the initial fall of the market value of equity
investments is reflected in the shockedsolvency balance sheet
Must be called after the projection

**Changed:** `proj::Projection`
"""
function mkt_val0_adj!(proj::Projection, invs::InvPort,
                       mkt_eq, eq_type::Symbol)
  for 𝑖𝑛𝑣𝑒𝑠𝑡 ∈ invs.igs[:IGStock].investments
    if mkt_eq.eq2type[𝑖𝑛𝑣𝑒𝑠𝑡.name] == eq_type
      proj.val_0[1,:invest] +=
        mkt_eq.shock[eq_type] * 𝑖𝑛𝑣𝑒𝑠𝑡.mv_0
    end
  end
end


## S2Def1 -------------------------------------------------------
"""
`scr!(def::S2Def1)`

SCR for interest rate risk, sub-module `def::S2Def1`

**Changed:** `def::S2Def1`
"""
function scr!(def::S2Def1)
  var = def.tlgd ⋅ (def.u * def.tlgd) + def.v ⋅ def.slgd
  sigma_norm = -sqrt(var)/sum(def.tlgd)
  if sigma_norm <= def.scr_par[:low][1]
    def.scr[NET] = def.scr_par[:low][2] * sqrt(var)
  elseif sigma_norm <= def.scr_par[:medium][1]
    def.scr[NET] = def.scr_par[:medium][2] * sqrt(var)
  else
    def.scr[NET] = sum(def.tlgd)
  end
  def.scr[GROSS] = def.scr[NET]
end

## S2LifeBio ----------------------------------------------------
"""
`selectmort!(p::ProjParam, bio::S2LifeBio)`

Identify those model points that are subject to mortality
risk. This function does not properly take into account
second order effects due to the effect of boni.
However, for realistic portfolios second order effects are
unlikely to change the set of identified model points.

**Changed:** `bio::S2LifeBio  (bio.mp_select)`
"""
function selectmort!(p::ProjParam, bio::S2LifeBio)
  invs = InvPort(p.t_0, p.T, p.cap_mkt, p.invs_par...)
  for 𝑠𝑦𝑚𝑏 ∈ collect(keys(bio.shock))
    merge!(bio.mp_select,
           Dict(𝑠𝑦𝑚𝑏 => Array{Bool}(undef, length(p.l_ins.mps))))
    for (𝑚, 𝑚𝑝) ∈ enumerate(p.l_ins.mps)
      if (𝑠𝑦𝑚𝑏 == :sx_mass_pension) & (!𝑚𝑝.pension_contract)
        bio.mp_select[𝑠𝑦𝑚𝑏][𝑚] = false
      else
        tp = tpg(p.t_0,
                 p.cap_mkt.rfr.x,
                 𝑚𝑝)
        mp_shock = deepcopy(𝑚𝑝)
        bioshock!(mp_shock, bio, 𝑠𝑦𝑚𝑏)
        tp_shock = tpg(p.t_0,
                       p.cap_mkt.rfr.x,
                       mp_shock)
        bio.mp_select[𝑠𝑦𝑚𝑏][𝑚] = (tp_shock > tp)
      end
    end
  end
end

"""
`bioshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)`

Helper function: shock for biometric risk

**Changed:** `mp::ModelPoint`
"""
function bioshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)
  if symb in [:qx, :px]
    qxpxshock!(mp, bio, symb)
  elseif symb in [:sx_down, :sx_up,
                  :sx_mass_pension, :sx_mass_other]
    sxshock!(mp, bio, symb)
  elseif symb in [:cat]
    catshock!(mp, bio, symb)
  end
end

"""
`bioshock!(l_ins::LiabIns, bio::S2LifeBio, shock_symb::Symbol)`

Shock for biometric risk

**Changed:** `l_ins::LiabIns  (l_ins.mps)`
"""
function bioshock!(l_ins::LiabIns,
                   bio::S2LifeBio,
                   shock_symb::Symbol)
  for (𝑚, 𝑚𝑝) ∈ enumerate(l_ins.mps)
    if bio.mp_select[shock_symb][𝑚]
      bioshock!(𝑚𝑝, bio, shock_symb)
    end
  end
end

"""
`qxpxshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)`

Helper function: shock for mortality risk

**Changed:** `mp::ModelPoint`
"""
function qxpxshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)
  mp.prob[:qx] =
    min.(1, (1 + bio.shock[symb]) * convert(Array, mp.prob[:qx]))
  mp.prob[:sx] = min.(1 .- mp.prob[:qx], mp.prob[:sx])
  mp.prob[:px] =  1.0 .- mp.prob[:qx] - mp.prob[:sx]
end

"""
`sxshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)`

Helper function: shock for surrender risk

**Changed:** `mp::ModelPoint`
"""
function sxshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)
  if symb == :sx_down
    mp.prob[:sx] =
      max.((1 + bio.shock[:sx_down]) * convert(Array, mp.prob[:sx]),
          convert(Array,
                  mp.prob[:sx]) .+
                  bio.shock_param[:sx_down_threshold])
  elseif symb == :sx_up
    mp.prob[:sx] =
      min.(1, (1 + bio.shock[symb]) * convert(Array, mp.prob[:sx]))
  elseif symb == :sx_mass_pension
    mp.prob[1, :sx] = bio.shock[symb]
  elseif symb == :sx_mass_other
    mp.prob[1, :sx] = bio.shock[symb]
  end
  mp.prob[:qx] = min.(1 .- mp.prob[:sx], mp.prob[:qx])
  mp.prob[:px] =  1.0 .- mp.prob[:qx] - mp.prob[:sx]
end

"""
`catshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)`

Shock for mortality catastrophe risk

**Changed:** `mp::ModelPoint`
"""
function catshock!(mp::ModelPoint, bio::S2LifeBio, symb::Symbol)
  mp.prob[1, :qx] = min(1, mp.prob[1, :qx] + bio.shock[symb])
  mp.prob[1, :sx] = min(1 .- mp.prob[1, :qx], mp.prob[1, :sx])
  mp.prob[:px] =  1.0 .- mp.prob[:qx] - mp.prob[:sx]
end

## S2LifeCost ---------------------------------------------------
"""
`costshock!(invs::InvPort, l_ins::LiabIns, cost::S2LifeCost)`

Shock for expense risk

**Changed:** `invs::InvPort`, `l_ins::LiabIns`
"""
function costshock!(invs::InvPort,
                    l_ins::LiabIns,
                    cost::S2LifeCost)
  shock_eoy =
    (1 + cost.shock[:cost]) *
    (1 + cost.shock_param[:infl]) .^ collect(1:l_ins.dur)
  for 𝑠𝑦𝑚𝑏 ∈ collect(keys(invs.igs))
    invs.igs[𝑠𝑦𝑚𝑏].cost.rel .*= shock_eoy
    invs.igs[𝑠𝑦𝑚𝑏].cost.abs .*= shock_eoy
  end
  for 𝑚𝑝 ∈ l_ins.mps
    𝑚𝑝.λ[:, :boy] *= (1 + cost.shock[:cost])
    𝑚𝑝.λ[:, :eoy] *= (1 + cost.shock[:cost])
    𝑚𝑝.λ[:, :infl] .+= cost.shock_param[:infl]
    𝑚𝑝.λ[:, :cum_infl] =
      𝑚𝑝.λ[1, :cum_infl] / (1 + 𝑚𝑝.λ[1, :infl]) *
      cumprod(1 .+ 𝑚𝑝.λ[:, :infl])
  end
end

## S2Op ---------------------------------------------------------
"""
`scr!(op::S2Op, bscr)`

SCR for interest rate risk, sub-module `op`

**Changed:** `op`
"""
function scr!(op::S2Op, bscr)
  ## SCR for operational risk
  op.comp_prem =
    op.fac[:prem] *
    (op.prem_earned +
       max(0,
           op.prem_earned -
             op.fac[:prem_py] * op.prem_earned_prev))
  op.comp_tp = op.fac[:tp]  * max(0, op.tp)
  op.scr =
    min(op.fac[:bscr] * bscr, max(op.comp_prem, op.comp_tp)) +
    op.fac[:cost] * op.cost_ul
end

## S2 -----------------------------------------------------------
"""
`scr!(s2::S2, tax_credit_0::Float64)`

Total SCR

**Changed:** `s2`
"""
function scr!(s2::S2, tax_credit_0::Float64)
  s2.bscr = scr(s2, s2.corr)
  scr!(s2.op, s2.bscr[GROSS])
  s2.adj_tp =
    -max(0.0, min(s2.bscr[GROSS] - s2.bscr[NET], fdb(s2, :be)))
  s2.adj_dt =
    -max(tax_credit_0 - (s2.bscr[GROSS] + s2.op.scr + s2.adj_tp),
         0)
  s2.scr = s2.bscr[GROSS] + s2.adj_tp + s2.adj_dt + s2.op.scr
end
