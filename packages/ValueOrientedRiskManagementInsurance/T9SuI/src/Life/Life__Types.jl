export CapMkt, DetermProcess, Stock, RiskFreeRate
export Invest, InvestStock, InvestCash
export InvestGroup, IGCost, IGStock, IGCash
export InvPort
export Alloc
export Product, ModelPoint, LiabIns
export LiabOther, Debt
export Dynamic
export Projection


## capital market -----------------------------------------------


"A stochastic or deterministc process representing a part of the
Capital market. It always has an object `x` representing the
development in time"
abstract type Process end


"Deterministic process, currently the only type of process
implemented"
abstract type DetermProcess <: Process end

"A deterministic process representing a stock index. Additional
objects"
mutable struct Stock <: DetermProcess
  "`Float64`: Initial value of `x`"
  x_0::Float64
  "`Vector{Float64}`: Process value for each Year"
  x::Vector{Float64}
  "`Float64`: Yield from process during year `t_0`
  (before the start of the projection)"
  yield_0::Float64
end

"A deterministic process representing a short rate"
mutable struct RiskFreeRate <: DetermProcess
  "`Vector{Float64}`: Process value for each Year"
  x::Vector{Float64}
  "`Float64`: Yield from process during year `t_0`
  (before the start of the projection)"
  yield_0::Float64
end

"A collection of `Process` objects which represents a
capital market. Currently we only have two deterministic
processes, `stock::Stock` and `rfr::RiskFreeRate`."
mutable struct CapMkt
  "`Stock`: Process describing a single deterministic stock"
  stock::Stock
  "`RiskFreeRate`: Process describing the (deterministic) risk
  free interest rate"
  rfr::RiskFreeRate
end

## investments --------------------------------------------------

"Represents an individual investments and its development in
time."
abstract type Invest end

dict_ig = Dict{Symbol, Symbol}(:IGStock => :InvestStock,
                               :IGCash => :InvestCash)

"`Invest` object associated with a `Stock` process"
mutable struct InvestStock <: Invest
  "`Symbol`:  Name of investment"
  name::Symbol
  "`Stock <: DetermProcess`: Associated stock process"
  proc::Stock
  "`Float64`: Initial market value"
  mv_0::Float64
  "`Vector{Float64}`: Market value in time"
  mv::Vector{Float64}
end

"`Invest` object associated with a `RiskFreeRate` process"
mutable struct InvestCash <: Invest
  "`Symbol`:  Name of investment"
  name::Symbol
  "`RiskFreeRate <: DetermProcess`: Associated cash process"
  proc::RiskFreeRate
  "`Float64`: Initial market value"
  mv_0::Float64
  "`Vector{Float64}`: Development of market value in time"
  mv::Vector{Float64}
  "`Float64`: Loss given default"
  lgd::Float64
  "`Symbol`:  Rating of counter party"
  cqs::Symbol
end

"A group of `Invest` objects of the same sub-type"
abstract type InvestGroup  end

"Allocation of investments within an `InvestGroup` object `ig`"
mutable struct Alloc  ## asset allocation for each year
  "`Vector{Symbol}`: Name of investments within invest group
  (the indices correpond to the indices of `ig.investments`)"
  name::Vector{Symbol}
  "`Vector{Float64}`: Allocation to investment group in time"
  total::Vector{Float64}
  "`Matrix{Float64}`: `all[τ, i]` is the allocation to `i`th
  investment of the investment group during year `τ`"
  all::Matrix{Float64}
  "Vector{Float64}`: Loss given default for each counter party
  (where applicable)"
  lgd::Vector{Float64}
  "`Vector{Symbol}`: Rating for each counter party
  (where not applicable: `:na`)"
  cqs::Vector{Symbol}
end

"Investment costs for an `InvestGroup` object `ig`"
mutable struct IGCost
  "`Vector{Float64}`: Relative costs per year incl. inflation"
  rel::Vector{Float64}
  "`Vector{Float64}`: Absolute costs per year incl. inflation"
  abs::Vector{Float64}
  "`Vector{Float64}`: Inflation for relative costs"
  infl_rel::Vector{Float64}
  "`Vector{Float64}`: Inflation for absolute costs"
  infl_abs::Vector{Float64}
  "`Vector{Float64}`: Cumulative inflation for relative costs"
  cum_infl_rel::Vector{Float64}
  "`Vector{Float64}`: Cumulative inflation for absolute costs"
  cum_infl_abs::Vector{Float64}
  "`Vector{Float64}`: Total costs per year (end of year)"
  total::Vector{Float64}
end

"Invest Group for `Invest` object `InvestStock`"
mutable struct IGStock <: InvestGroup
  "`Vector{InvestStock}`: Invest objects of the same type"
  investments::Vector{InvestStock}
  "`Float64`: Initial total market value of invest group"
  mv_0::Float64
  "`Vector{Float64}`: Market value of invest group in time"
  mv::Vector{Float64}
  "`Alloc`: Allocation of investments within invest group"
  alloc::Alloc
  "`InvestCost`: investment costs of invest group"
  cost::IGCost
end

"Invest Group for `Invest` object `InvestCash`"
mutable struct IGCash <: InvestGroup
  "`Vector{InvestCash}`: Invest objects of the same type"
  investments::Vector{InvestCash}
  "`Float64`: Initial total market value of invest group"
  mv_0::Float64
  "`Vector{Float64}`: Market value of invest group in time"
  mv::Vector{Float64}
  "`Alloc`: Allocation of investments within invest group"
  alloc::Alloc
  "`InvestCost`: investment costs of invest group"
  cost::IGCost
end

"Investment portfolio"
mutable struct InvPort
  "`Int`:  Year in which projection starts"
  t_0::Int
  "`Float64`: Initial market value"
  mv_0::Float64
  "`Vector{Float64}`: Market value at the Beginning of each year"
  mv_boy::Vector{Float64}
  "`Vector{Float64}`: Market value at the end of each year"
  mv::Vector{Float64}
  "`Vector{Float64}`: Investment yield per year"
  yield::Vector{Float64}
  "`Vector{Float64}`: Investment costs per year"
  cost::Vector{Float64}
  "`Dict{Symbol, InvestGroup}`: Investment groups in the
  investment porfolio"
  igs::Dict{Symbol, InvestGroup}
end

## insurance liabilities ----------------------------------------

"Life insurance product / tariff"
mutable struct Product
  "`Int`: Duration of product"
  dur::Int
  "`Vector{Float64}`: Pricing discount rate for each year"
  rfr::Vector{Float64}
  "`DataFrame`: Biometric probabilities for pricing
  (`:qx`, `:sx`, `:px`)"
  prob::DataFrame
  "`DataFrame`: Premium/benefit profile
  (`:qx`, `:sx`, `:px`, `:prem`)"
  β::DataFrame
  "`DataFrame`: Cost profile (`:boy`, `:eoy`)"
  λ::DataFrame
  "`Float64`: Normalized premium for insured sum == 1"
  prem_norm::Float64
end

"""
Model point for the liability portfolio representing a number
of insured with the same contract parameters and the same
biometric parameters

**Time model:**

```
  project time τ:               0
  real time t:     t_start      t_0
  product time s:  0            s_0
                   |------------|-------------------|-----------
                                |-------------------|
                                         dur
                   |--------------------------------|
                              product.dur
```
"""
mutable struct ModelPoint
  "`Int`:  Number of contracts in model point"
  n::Int
  "`Int`:  Year in which contract has been taken out"
  t_start::Int
  "`Int`: Remaining duration relative to `t_0`
  (start of projection)"
  dur::Int
  "`DataFrame`: Best estimate biometric probabilities
  (`:qx`, `:sx:`, `:px`)"
  prob::DataFrame
  "`Vector{Float64}`: Survivors at beginning of year"
  lx_boy::Vector{Float64}
  "`Float64`: The value of lx_boy for the next year"
  lx_boy_next::Float64
  "`DataFrame`: Conditional benefits / premium
  (`:qx`, `:sx`, `:px`, `:prem`)"
  β::DataFrame
  "`DataFrame`: Conditional costs profile (`:boy`, `:eoy`)"
  λ::DataFrame
  "`Float64`: Hypothetical bonus rate communicated when contract
  was sold"
  bonus_rate_hypo::Float64
  "`Float64`: Discount rate for pricing at `t_0`"
  rfr_price_0::Float64
  "`Vector{Float64}`: Discount rate for pricing"
  rfr_price::Vector{Float64}
  "`Float64`: Initial technical provisions for pricing"
  tpg_price_0::Float64
  "`Vector{Float64}`: Technical provisions for pricing"
  tpg_price::Vector{Float64}
  "`Vector{Float64}`: Going concern factor
  (fraction of policy holders per year)"
  gc::Vector{Float64}
  "`Bool`: Marker whether it is a pension contract
  (for S2-calculation)"
  pension_contract::Bool
end

"Liability portfolio"
mutable struct LiabIns
  "`Int`: Number of model points"
  n::Int
  "`Int`: Year in which projection starts"
  t_0::Int
  "`Int`: Maximum remaining duration in liability portfolio"
  dur::Int
  "`Vector{ModelPoint}`: Model points in liability portfolio"
  mps::Array{ModelPoint, 1}
  "`Vector{Float64}`: Scaling for going concern modeling"
  gc::Vector{Float64}
  "`Vector{Float64}`: `Δgc[t] = gc[t + 1] - gc[t]`"
  Δgc::Vector{Float64}
end

## other liabilities --------------------------------------------

"Debt issued by the company"
mutable struct Debt
  "`Symbol`: Name of this loan"
  name::Symbol
  "`Int`: Time at which loan has been taken"
  t_init::Int
  "`Int`: Time at which loan matures"
  t_mat::Int
  "`Int`: Time at loan has been taken relative to `t_0`"
  τ_init::Int
  "`Int`: Remaining duration of loan relative to `t_0`"
  τ_mat::Int
  "`Float64`: Nominal amount"
  nominal::Float64
  "`Float64`: Yearly coupon payment (absolute value)"
  coupon::Float64
end

"Portfolio of other liabilities"
mutable struct LiabOther
  "`Vector{Debt}`:  Vector with subordinated debt"
  subord::Vector{Debt}
end

## dynamics -----------------------------------------------------

"Dynamic projection parameters for a `Projection` object"
mutable struct Dynamic
  "`Float64`: Bonus factor"
  bonus_factor::Float64
  "`Float64`: Desired surplus ratio"
  quota_surp::Float64
  "`Vector{Float64}`: Free surplus for bonus calculation"
  free_surp_boy::Vector{Float64}
end

## cashflow projection ------------------------------------------

"Projection of a life insurer"
mutable struct Projection
  "`Int`: Start of projection"
  t_0::Int
  "`Int`: Length of projection"
  dur::Int
  "`DataFrame`: Cashflows (`:qx`,`:sx`,`:px`,`:prem`,`:λ_boy`,
  `:λ_eoy`, `:bonus`, `:invest`,`:new_debt`,`:l_other`,`:profit`,
  `:tax`, `:divid`, `:gc`, `:Δtpg`, `:cost_prov`)"
  cf::DataFrame
  "`DataFrame`: Best estimate initial valuation (`:invest`,
  `:tpg`, `:l_other`, `:surplus`, `:bonus`, `:cost_prov`)"
  val_0::DataFrame
  "`DataFrame`: Best estimate valuation for each year (`:invest`,
  `:tpg`, `:l_other`, `:surplus`, `:bonus`, `:cost_prov`)"
  val::DataFrame
  "`Float64`: Rate at which profit is taxed"
  tax_rate::Float64
  "`Float64`: Initial tax credit"
  tax_credit_0::Float64
  "`Vector{Float64}`: Tax credit for each year"
  tax_credit::Vector{Float64}
  "`Vector{Float64}`: Weighted fixed costs for
  going concern modeling"
  fixed_cost_gc::Vector{Float64}
end
