using ValueOrientedRiskManagementInsurance
using DataFrames
using Test
using Distributions

println("start NonLife.jl...")

function logpar2statpar(m_s::Vector)
  Real[exp(m_s[1] + m_s[2]^2 / 2),
       √(exp(m_s[2]^2)-1) * exp(m_s[1] + m_s[2]^2 / 2)]
end

function statpar2logpar(μ_σ::Vector)
  vc = μ_σ[2]/μ_σ[1]
  Real[log(μ_σ[1]) - 0.5 * log(1+vc^2), √(log(1+vc^2))]
end

"""
   dr = ( θ(t)-ar ) dt + σ dW
"""
mutable struct HullWhite
  t₀::Real
  T::Real
  δt::Real
  θ::Vector{Real}
  a::Real
  σ::Real
end

function HullWhite(t₀::Real,
                   δt::Real,
                   θ::Vector{Real},
                   a::Real,
                   σ::Real)
  T = t₀ + length(θ) * δt
  HullWhite(t₀, T, δt, θ, a, σ)
end

periods_int(t::Real, hw::HullWhite) = int(div(t, hw.Δt))
periods_frac(t::Real, hw::HullWhite) = t/hw.Δt - period_int(t, hw)

function r(rstart::Real, k::Int, Δk::Int, hw::HullWhite)
  μ =
    exp(-hw.a*Δk*hw.δt)/hw.a *
    (hw.a * rstart  +
     sum([(exp(-hw.a*𝑗*hw.δt) - exp(-hw.a*(𝑗-1)*hw.δt)) *
           hw.θ[k+𝑗-1] for 𝑗 ∈ 1:Δk]))
  std = hw.σ * √( (1-2exp(-2hw.a*Δk*hw.δt)) / (2hw.a) )
  Normal(μ, std)
end

nllobs = [:fire, :liab, :theft]
n_nl = length(nllobs)
nl_names = [ucfirst(string(nllobs[𝑖])) for 𝑖 ∈ 1:n_nl]
df_claims = Vector(n_nl)
claims = Vector(n_nl)
res = Vector(n_nl)
β = Vector(n_nl)

claimpath = "test/NonLife_Input_Claims_"
for 𝑖 ∈ 1:n_nl
  df_claims[𝑖] =
    CSV.read(claimpath * nl_names[𝑖]  * ".csv",
              header = false)
  res[𝑖] = Mack(df_claims[𝑖])
  β[𝑖] = res[𝑖].futureclaims / sum(res[𝑖].futureclaims)
end


#
# mean, sde -> logmean, logsigma
# R[i] = LogNormal(log_mean[i], log_sigma[i])
# v⋅mack[i].β * R[i]
#
# v: stochastic discont
# β
# R[i] = stochastic total undiscounted future paiments,
#

println("...end NonLife.jl")
