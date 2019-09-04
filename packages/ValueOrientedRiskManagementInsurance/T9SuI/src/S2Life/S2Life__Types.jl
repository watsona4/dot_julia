export GROSS, NET
export S2, S2Mkt, S2MktEq, S2MktInt
export ProjParam

"Convenience index name"
const GROSS = 1
"Convenience index name"
const NET = 2

"Abstract type for an S2 module"
abstract type S2Module end

"Dummy type for those S2 modules that have not been implemented"
mutable struct S2NotImplemented <: S2Module
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end

function S2NotImplemented(x...)
  return S2NotImplemented(zeros(Float64, 2))
end

"S2 market property risk module, not yet implemented"
const S2MktProp = S2NotImplemented
"S2 market spread risk module, not yet implemented"
const S2MktSpread = S2NotImplemented
"S2 market currency risk module, not yet implemented"
const S2MktFx = S2NotImplemented
"S2 market concentration risk module, not yet implemented"
const S2MktConc = S2NotImplemented
"S2 default (type 2) risk module, not yet implemented"
const S2Def2 = S2NotImplemented
"S2 life morbidity risk module, not yet implemented"
const S2LifeMorb = S2NotImplemented
"S2 life revision risk module, not yet implemented"
const S2LifeRevision = S2NotImplemented
"S2 health risk module, not yet implemented"
const S2Health = S2NotImplemented
"S2 non-life risk module, not yet implemented"
const S2NonLife = S2NotImplemented

"Projection parameters for S2-calculations without
S2 calibration parameters"
mutable struct ProjParam
  "`Int`: Year in which projection starts"
  t_0::Int
  "`Int`: Year in which projection ends"
  T::Int
  "`CapMkt`: Capital market"
  cap_mkt::CapMkt
  "`Vector{Any}`: Parameters for the construction of the InvPort
  object with the exception of `t_0::Int`, `T::Int`,
  `cap_mkt::CapMkt`"
  invs_par::Vector{Any}
  "`LiabIns`: Liability porfolio (without other liabilites)"
  l_ins::LiabIns
  "`LiabOther`: Other liabilities"
  l_other::LiabOther
  "`Dynamic`: Dynamic projection parameters"
  dyn::Dynamic
  "`Float64`: (constant) tax rate during projection"
  tax_rate::Float64
  "`Float64`: Initial tax credit"
  tax_credit_0::Float64
end

## solvency 2 market risk =======================================
"Solvency 2 market risk: interest rate risk"
mutable struct S2MktInt <: S2Module
  "`Symbol`: Name of object type to be shocked"
  shock_object::Symbol
  "`Dict{Symbol, Any}`: Interest rate shocks"
  shock::Dict{Symbol, Any}
  "`Float64`: Minumum upwards shock"
  spot_up_abs_min::Float64
  "`DataFrame`:  Shocked balance sheets"
  balance::DataFrame
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
  "`Bool`: Was interest shocked upwards to obtain SCR?"
  scen_up::Bool
end

"Solvency 2 market risk: equity risk"
mutable struct S2MktEq <: S2Module
  "`Symbol`: Name of object type to be shocked"
  shock_object::Symbol
  "`Dict{Symbol, Symbol}`: Equity type for each invested stock"
  eq2type::Dict{Symbol, Symbol}
  "`Dict{Symbol, Any}`: Equity shocks"
  shock::Dict{Symbol,Any}
  "`DataFrame`:  Shocked balance sheets"
  balance::DataFrame
  "`Matrix{Float64}`: Correlation matrix for equity types"
  corr::Matrix{Float64}
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end

"Solvency 2 market risk"
mutable struct S2Mkt <: S2Module
  "`Vector{S2Module}`: Sub-modules for market risk"
  mds::Vector{S2Module}
  "`Matrix{Float64}`: Correlation matrix if upwards shock was
  used in the calculation of the SCR for interest risk"
  corr_up::Matrix{Float64}
  "`Matrix{Float64}`: Correlation matrix if downwards shock was
  used in the calculation of the SCR for interest risk"
  corr_down::Matrix{Float64}
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end

## solvency 2 default risk ======================================
"Solvency 2 default risk of type 1"
mutable struct S2Def1 <: S2Module
  "`Vector{Float64}`: Total loss given default per rating"
  tlgd::Vector{Float64}
  "`Vector{Float64}`: Squared loss given default per rating"
  slgd::Vector{Float64}
  "`Matrix{Float64}`: Matrix u for variance calculation"
  u::Matrix{Float64}
  "`Vector{Float64}`: Vector v for variance calculation"
  v::Vector{Float64}
  "`Dict{Symbol, Vector{Float64}}`: Parameters for the SCR
  calculation depending on whether the normalized standard
  deviation is low, medium, or high"
  scr_par::Dict{Symbol, Vector{Float64}}
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end

"Solvency 2 default risk"
mutable struct S2Def <: S2Module
  "`Vector{S2Module}`: Sub-modules for default risk"
  mds::Vector{S2Module}
  "`Matrix{Float64}`: Correlation matrix for default risk"
  corr::Matrix{Float64}
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end

## solvency 2 life risk =========================================
"Solvency 2 life risk: biometric risks: mortality, longevity,
surrender"
mutable struct S2LifeBio <: S2Module
  "`Symbol`: Name of object type to be shocked"
  shock_object::Symbol
  "`Dict{Symbol, Any}`: biometric shocks"
  shock::Dict{Symbol, Any}
  "`Dict{Symbol, Float64}`: Additional parameters for calculating
  shocks, may be empty"
  shock_param::Dict{Symbol, Float64}
  "`DataFrame`:  Shocked balance sheets"
  balance::DataFrame
  "`Dict{Symbol, Vector{Bool}}`: Indicator which model points
  have been selected to be shocked"
  mp_select::Dict{Symbol, Vector{Bool}}
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end


"Solvency 2 life risk: expense risk"
mutable struct S2LifeCost <: S2Module
  "`Symbol`: Name of object type to be shocked"
  shock_object::Symbol
  "`Dict{Symbol, Any}`: biometric shocks"
  shock::Dict{Symbol, Any}
  "`Dict{Symbol, Float64}`: Additional parameters for calculating
  shocks"
  shock_param::Dict{Symbol, Float64}
  "`DataFrame`:  Shocked balance sheets"
  balance::DataFrame
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end

"Solvency 2 life risk"
mutable struct S2Life <: S2Module
  "`Vector{S2Module}`: Sub-modules for life risk"
  mds::Vector{S2Module}
  "`Matrix{Float64}`: Correlation matrix for life risk"
  corr::Matrix{Float64}
  "`Vector{Float64}`: Gross and net SCR"
  scr::Vector{Float64}
end

## solvency 2 operational risk ==================================
"Solvency 2 operational risk"
mutable struct S2Op <: S2Module
  "`Dict{Symbol, Float64}`: Factors for SCR calculation"
  fac::Dict{Symbol, Float64}
  "`Float64`: Earned premium (previous year)"
  prem_earned::Float64
  "`Float64`: Earned premium (year before previous year)"
  prem_earned_prev::Float64
  "`Float64`: Technical provisions (incl. bonus but without
  unit linked)"
  tp::Float64
  "`Float64`: Temporary result, SCR component based on technical
  provisions"
  comp_prem::Float64
  "`Float64`: Temporary result, SCR component based on earned
  premiums"
  comp_tp::Float64
  "`Float64`: Costs for unit linked"
  cost_ul::Float64
  "`Vector{Float64}`: Gross and net SCR"
  scr::Float64
end

## solvency 2 total =============================================
"Solvency 2 (total)"
mutable struct S2 <: S2Module
  "`Vector{S2Module}`: Solvency 2 modules witout op-risk "
  mds::Vector{S2Module}
  "`DataFrame`: Unshocked best estimate balance sheet"
  balance::DataFrame
  "`Matrix{Float64}`: Correlation matrix for calculation of BSCR"
  corr::Matrix{Float64}
  "`Vector{Float64}`: Gross and net BSCR"
  bscr::Vector{Float64}
  "`Float64`: Adjustment for riskmitigating effect from
  discretionary bonus"
  adj_tp::Float64
  "`Float64`: Adjustment for riskmitigating effect from deferred
  taxes"
  adj_dt::Float64
  "`S2Op`: Solvency 2 module for operational risk"
  op::S2Op
  "`Float64`: SCR"
  scr::Float64
  "`Float64`: Modified investments for the calculation of the
  SCR-ratio"
  invest_mod::Float64
  "`Float64`: Modified liabilities for the calculation of the
  SCR-ratio"
  liabs_mod::Float64
  "`Float64`: Cost of capital factor (spread over risk free)"
  coc::Float64
  "`Float64`: Risk margin (part of S2 technical provisions)"
  risk_margin::Float64
  "`Float64`: SCR-ratio"
  scr_ratio::Float64
end
