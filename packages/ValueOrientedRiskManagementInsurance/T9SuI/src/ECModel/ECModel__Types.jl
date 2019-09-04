export GaussCopula, ProfitLoss, PLInsurance, PLInvestments,
PLTotal, BusinessUnit, BuInsurance, BuInvestments, Total

"Gaussian copula"
mutable struct GaussCopula
  "`Int`: Number of marginal distributions"
  n::Int
  "`Array{Float64,2} `: Correlation matrix"
  Σ::Array{Float64,2}
  "`Vector{ContinuousUnivariateDistribution}`:
  Marginal distributions"
  marginals::Vector{ContinuousUnivariateDistribution}
end

"Profit and loss account of an insurance company component"
abstract type ProfitLoss end

"Profit loss account for the insurance result from a line
of business (lob)"
mutable struct PLInsurance <: ProfitLoss
  "`Real`: Premium for lob"
  premium::Real
  "`Real`: Administration costs of lob"
  costs::Real
  "`Real`: Fraction of premium which is quota reinsured"
  ceded::Real
  "`Vector{Real}`: Insurance profit from lob"
  profit::Vector{Real}
  "`Real`: Expected insurance profit from lob"
  profit_mean::Real
  "`Real`: Economic capital for lob"
  eco_cap::Real
  "`Real`: Return on risk adjusted capital for lob"
  rorac::Real
end

"Profit loss account for the investment result result"
mutable struct PLInvestments <: ProfitLoss
  "`Real`: Invested funds beginning of period"
  invest_bop::Real
  "`Real`: Administration costs"
  costs::Real
  "`Vector{Real}`: Investment profit"
  profit::Vector{Real}
  "`Real`: Expected investment profit"
  profit_mean::Real
  "`Real`: Economic capital for asset management"
  eco_cap::Real
  "`Real`: Return on risk adjusted capital for asset management"
  rorac::Real
end

"Profit loss account for the aggregated insurance company"
mutable struct PLTotal <: ProfitLoss
  "`Vector{Real}`: Profit of company"
  profit::Vector{Real}
  "Real`: Expected profit of company"
  profit_mean::Real
  "Economic capital for the company"
  eco_cap::Real
  "`Real`: Return on risk adjusted capital for the company"
  rorac::Real
end

" A business unit is a line of business or investments"
abstract type BusinessUnit end

"Business unit: Line of business"
mutable struct BuInsurance <: BusinessUnit
  "`AbstractString`:  id of business unit"
  id::Symbol
  "`AbstractString`:  Name of business unit"
  name::AbstractString
  "`PLInsurance`: profit loss account for lob
  (gross of reinsurance)"
  gross::PLInsurance
  "`PLInsurance`: profit loss account for lob
  (net of reinsurance)"
  net::PLInsurance
end

"Business unit: Investments"
mutable struct BuInvestments <: BusinessUnit
  "`AbstractString`:  id of business unit"
  id::Symbol
  "`AbstractString`:  Name of business unit"
  name::AbstractString
  "`Real`:  Initial capital"
  init::Real
  "`PLInvestments`: profit loss account for investments
  (gross of reinsurance)"
  gross::PLInvestments
  "`PLInvestments`: profit loss account for investments
  (net of reinsurance)"
  net::PLInvestments
end

"Total company result"
mutable struct Total
  "`PLTotal`: profit loss account for company
  (gross of reinsurance)"
  gross::PLTotal
  "`PLTotal`: profit loss account for company
  (net of reinsurance)"
  net::PLTotal
end
