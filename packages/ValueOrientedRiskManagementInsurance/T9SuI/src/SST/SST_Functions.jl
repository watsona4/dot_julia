using Distributions

export value, delta, gammamatrix, Δrtk, rΔrtk, rtk, srtk,
       aggrstress, UP, DOWN

## Constructors -------------------------------------------------
function RiskFactor(σ::Vector{Float64},
                    corr::Array{Float64, 2},
                    x0::Vector{Float64},
                    h::Vector{Float64},
                    add::Vector{Bool})
  return RiskFactor((σ * σ') .* corr, x0, h, add)
end

## Valuation ----------------------------------------------------
"""
`value(t::Int, zb::ZeroBond, x::Vector{Float64}, rf::RiskFactor,
  cap_mkt::SSTCapMkt)`

Calculates the value of a zero bond (after sensitivity `x`)
"""
function value(t::Int,
               zb::ZeroBond,
               x::Vector{Float64},
               rf::RiskFactor,
               cap_mkt::SSTCapMkt)
  x_spot = cap_mkt.spot[zb.index] + x[zb.index]
  val = zb.nom / (1 + x_spot)^zb.τ
  if t != 0
    val *= (1 + cap_mkt.spot[t] + x[t])^t
  end
  return val
end

"""
`value(t::Int, si::StockIndex,x::Vector{Float64}, rf::RiskFactor,
  cap_mkt::SSTCapMkt)`

Calculates the value of a stock (after sensitivity `x`)
"""
function value(t::Int,
               si::StockIndex,
               x::Vector{Float64},
               rf::RiskFactor,
               cap_mkt::SSTCapMkt)
  return x[si.index] * si.nom * (1 + cap_mkt.stock_increase)^t
end

"""
`value(t::Int, assts::Vector{Asset}, x::Vector{Float64},
  rf::RiskFactor, cap_mkt::SSTCapMkt)`

Calculates the value of the asset portfolio
(after sensitivity `x`)
"""
function value(t::Int,
               assts::Vector{Asset},
               x::Vector{Float64},
               rf::RiskFactor,
               cap_mkt::SSTCapMkt)
  val = 0.0
  for 𝑎𝑠𝑠𝑒𝑡 ∈ assts
    val += value(t, 𝑎𝑠𝑠𝑒𝑡, x, rf, cap_mkt)
  end
  return val
end

"""
`value(t::Int, liabs::Liabilities, x::Vector{Float64},
  rf::RiskFactor, cap_mkt::SSTCapMkt)`

Calculates the value of the liability portfolio
(after sensitivity `x`)
"""
function value(t::Int,
               liabs::Liabilities,
               x::Vector{Float64},
               rf::RiskFactor,
               cap_mkt::SSTCapMkt)
  T = length(cap_mkt.spot)
  x_spot = cap_mkt.spot[1:T] + x[1:T]
  x_mort = x[liabs.index_mort]
  val = 0.0
  for 𝜏 ∈ 1:length(liabs.B_PX)
    val +=
      prod(1 .- liabs.qx[1:𝜏] .* x_mort) *
      liabs.B_PX[𝜏] / (1 + x_spot[𝜏])^𝜏
  end
  if t != 0
    val *= (1 + cap_mkt.spot[t] + x[t])^t
  end
  return val
end

"""
`rtk(t::Int, assets::Vector{Asset}, liabs::Liabilities,
  x::Vector{Float64}, rf::RiskFactor, cap_mkt::SSTCapMkt)`

Calculates the risk bearing capital (after sensitivity `x`)
"""
rtk(t::Int,
    assets::Vector{Asset},
    liabs::Liabilities,
    x::Vector{Float64},
    rf::RiskFactor,
    cap_mkt::SSTCapMkt) =
  value(t, assets, x, rf, cap_mkt) -
  value(t,liabs, x, rf, cap_mkt)

## capital calculation ------------------------------------------
const UP, DOWN = 1, -1

"""
`srtk(shift::Int, assets::Vector{Asset}, liabs::Liabilities,
  rf::RiskFactor, cap_mkt::SSTCapMkt)`

Calculates (linear) sensitivities for rtk
"""
function srtk(shift::Int,
             assets::Vector{Asset},
             liabs::Liabilities,
             rf::RiskFactor,
             cap_mkt::SSTCapMkt)
  x = deepcopy(rf.x0)
  n = length(x)
  rtk_shift = Array{Float64}(undef, n)
  for 𝑖 ∈ 1:n
    x[𝑖] += shift * rf.h[𝑖]
    rtk_shift[𝑖] = rtk(1, assets, liabs, x, rf, cap_mkt)
    x[𝑖] -= shift * rf.h[𝑖]  ## restore old value for y[i]
  end
  return rtk_shift
end

"""
`srtk(shift_1::Int, shift_2::Int, assets::Vector{Asset},
  liabs::Liabilities, rf::RiskFactor, cap_mkt::SSTCapMkt)`

Calculates quadratic sensitivities for rtk
"""
function srtk(shift_1::Int,
             shift_2::Int,
             assets::Vector{Asset},
             liabs::Liabilities,
             rf::RiskFactor,
             cap_mkt::SSTCapMkt)
  x = deepcopy(rf.x0)
  n = length(x)
  rtk_shift_shift = Array{Float64}(undef, n, n)
  for 𝑖 ∈ 1:n
    for 𝑘 ∈ 1:n
      x[𝑖] += shift_1 * rf.h[𝑖]
      x[𝑘] += shift_2 * rf.h[𝑘]
      rtk_shift_shift[𝑖, 𝑘] =
        rtk(1, assets, liabs, x, rf, cap_mkt)
      x[𝑖] -= shift_1 * rf.h[𝑖]  ## restore old value for x[𝑖]
      x[𝑘] -= shift_2 * rf.h[𝑘]  ## restore old value for x[𝑘]
    end
  end
  return rtk_shift_shift
end

Δ(rf::RiskFactor) =
  Float64[rf.add[𝑖] ?  rf.h[𝑖] : rf.x0[𝑖] * rf.h[𝑖]
          for 𝑖 ∈ 1:length(rf.x0)]

"""
`delta(assets::Vector{Asset}, liabs::Liabilities, rf::RiskFactor,
  cap_mkt::SSTCapMkt)`

Calculates the δ-vector
"""
delta(assets::Vector{Asset},
      liabs::Liabilities,
      rf::RiskFactor,
      cap_mkt::SSTCapMkt) =
  (srtk(UP, assets, liabs, rf, cap_mkt) -
     srtk(DOWN, assets, liabs, rf, cap_mkt)) ./ (2Δ(rf))

"""
`gammamatrix(assets::Vector{Asset}, liabs::Liabilities,
  rf::RiskFactor, cap_mkt::SSTCapMkt)`

Calculates the Γ-matrix
"""
function gammamatrix(assets::Vector{Asset},
               liabs::Liabilities,
               rf::RiskFactor,
               cap_mkt::SSTCapMkt)
  Δx = Δ(rf)
  rtk_uu = srtk(UP, UP, assets, liabs, rf, cap_mkt)
  rtk_ud = srtk(UP, DOWN, assets, liabs, rf, cap_mkt)
  rtk_du = srtk(DOWN, UP, assets, liabs, rf, cap_mkt)
  rtk_dd = srtk(DOWN, DOWN, assets, liabs, rf, cap_mkt)
  Γ_diag =
    (srtk(UP, assets, liabs, rf, cap_mkt) +
       srtk(DOWN, assets, liabs, rf, cap_mkt) .-
       2rtk(1,assets, liabs, rf.x0, rf, cap_mkt)) ./ (Δx .* Δx)
  Γ = Array{Float64}(undef, length(rf.x0), length(rf.x0))
  for 𝑖 ∈ 1:length(rf.x0)
    for 𝑘 ∈ 1:(𝑖-1)
      Γ[𝑖,𝑘] = (rtk_uu[𝑖,𝑘] -
                  rtk_ud[𝑖,𝑘] -
                  rtk_du[𝑖,𝑘] +
                  rtk_dd[𝑖,𝑘]) / (4 * Δx[𝑖] * Δx[𝑘])
      Γ[𝑘,𝑖] = Γ[𝑖,𝑘]
    end
    Γ[𝑖,𝑖] = Γ_diag[𝑖]
  end
  return Γ
end

"""
`Δrtk(Δx::Vector{Float64}, δ::Vector{Float64},
  Γ::Matrix{Float64})`

Calculates the shocked rtk based on shocks Δx
"""
Δrtk(Δx::Vector{Float64},
     δ::Vector{Float64},
     Γ::Matrix{Float64}) = (Δx ⋅ δ + 0.5 * Δx' * Γ * Δx)[1]

## random values for Δrtk
function rΔrtk(n_scen::Int,
               assets::Vector{Asset},
               liabs::Liabilities,
               rf::RiskFactor,
               cap_mkt::SSTCapMkt,
               x_index::Vector{Int},
               )
  r_Δx = rand(MvNormal(zeros(Float64, length(x_index)),
                       rf.Σ[x_index, x_index]),
              n_scen)
  r_Δrtk = Array{Float64}(undef, n_scen)
  δ = delta(assets, liabs, rf, cap_mkt)[x_index]
  Γ = gammamatrix(assets, liabs, rf, cap_mkt)[x_index, x_index]
  for 𝑚𝑐 ∈ 1:n_scen
    r_Δrtk[𝑚𝑐] = Δrtk(r_Δx[:, 𝑚𝑐], δ, Γ)
  end
  return r_Δrtk
end

##  Aggregate stress-scenarios to randomly generated values
##    r_Δrtk_no_stress.
##  We use the same approximation as in the shift method,
##    namely, two different stress scenarios cannot happen
##    in the same year.
function aggrstress(stress::Stress, r_Δrtk_no_stress)
  r_Δrtk = deepcopy(r_Δrtk_no_stress)
  n_scen = length(r_Δrtk)
  i = 0
  for 𝑠𝑐𝑒𝑛 ∈ 1:stress.n
    if stress.target[𝑠𝑐𝑒𝑛]
      n_adj = floor(Integer, n_scen * stress.prob[𝑠𝑐𝑒𝑛])
      for 𝑗 ∈ 1:n_adj
        r_Δrtk[i + 𝑗] += min(0, stress.Δrtk[𝑠𝑐𝑒𝑛])
      end
      i += n_adj
    end
  end
  return r_Δrtk
end
