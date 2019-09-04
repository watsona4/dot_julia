export Stress, Asset, Liabilities, StockIndex, ZeroBond,
       RiskFactor, SSTCapMkt

"Stress scenario"
mutable struct Stress
  "`Int`: Number of scenarios"
  n::Int
  "`Vector{AbstractString}`: Name of scenario"
  name::Vector{AbstractString}
  "`Vector{Bool}`: Is the particular scenario included?"
  target::Vector{Bool}
  "`Vector{Float64}`: Probability of the scenario"
  prob::Vector{Float64}
  "`Array{Float64,2}`: Impact of scenario"
  Δx::Array{Float64,2}
  "`Vector{Float64}`: Effect on RTK"
  Δrtk::Vector{Float64}
end

"Capital market"
mutable struct SSTCapMkt
  "`Vector{Float64}`: Risk-free spot rate curve"
  spot::Vector{Float64}
  "`Float64`: Expected relative increase of stock per year"
  stock_increase::Float64
end

"Abstract type for assets"
abstract type Asset end

"Zero bond (an instance of an asset)"
mutable struct ZeroBond <: Asset
  "`Float64`: Nominal value of the zero bond"
  nom::Float64
  "`Int`: Time to maturity (full years)"
  τ::Int
  "`Int`: Index of this risk factor"
  index::Int
end

"Investment in stock"
mutable struct StockIndex <: Asset
  "`Float64`: Initial value of investment"
  nom::Float64
  "`Int`: Index of this risk factor"
  index::Int
end

"Liability portfolio consisting of a single insurance contract"
mutable struct Liabilities
  "`Vector{Float64}`: Survival benefits"
  B_PX::Vector{Float64}
  "`Vector{Float64}`: Mortality probabilities"
  qx::Vector{Float64}
  "`Vector{Int}`: Index of this risk factor"
  index_mort::Vector{Int}
end

"Risk factor"
mutable struct RiskFactor
  "`Array{Float64,2}`: Covariance matrix for risk factors"
  Σ::Array{Float64,2}
  "`Vector{Float64}`: Expected value of risk factor: `x0 = E(x)`"
  x0::Vector{Float64}
  "`Vector{Float64}`: Sensitivity for each risk factor to
  calculate derivatives of RTK"
  h::Vector{Float64}
  "`Vector{Bool}`: Is the sensitivity additive?
  (Otherwise multiplicative)"
  add::Vector{Bool}
end
