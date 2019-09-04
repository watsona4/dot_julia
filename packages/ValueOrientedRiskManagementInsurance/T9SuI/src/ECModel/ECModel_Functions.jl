export rand, profit!, evaluate!, project, initialize

## Constructors  ################################################

"Creation of a Gaussian copula with marginal distributions"
function GaussCopula(
  margs::Array{ContinuousUnivariateDistribution},
  Σ::Array{Real,2})
  if (size(Σ,1) != size(Σ,2)) | (size(Σ,1) != length(margs))
    error("dimensions are different")
  end
  GaussCopula(size(Σ,1), Σ, margs)
end

function PLInsurance(input::DataFrame,
                     i::Int, n_scen::Int, is_net::Bool)
  pl = PLInsurance(0, 0, 0, Array{Real}(undef, n_scen), 0, 0, 0)
  pl.ceded = (is_net ? input[i, :re_ceded] : 0)
  pl.premium = input[i, :premium] * (1 - pl.ceded)
  pl.costs =
    input[i, :cost_ratio] * pl.premium +
    input[i, :re_costs] * (input[i, :premium] - pl.premium)
  return pl
end

function PLTotal(n_scen)
  PLTotal(Array{Real}(undef, n_scen), 0, 0, 0)
end

function BuInvestments(id::Symbol,
                       name::AbstractString,
                       bu_ins::Array{BusinessUnit},
                       cost_ratio::Real,
                       invest_init::Real,
                       n_scen::Int)
  gross = PLInvestments(invest_init, 0,
                        zeros(Real, n_scen), 0, 0, 0)
  net = deepcopy(gross)
  for 𝑖𝑛𝑠 ∈ bu_ins
    gross.invest_bop += 𝑖𝑛𝑠.gross.premium
    net.invest_bop += 𝑖𝑛𝑠.net.premium
  end
  gross.costs = cost_ratio * gross.invest_bop
  net.costs = cost_ratio * net.invest_bop
  return BuInvestments(id, name, invest_init, gross, net)
end

## Interface ####################################################

"""
`rand(gc::GaussCopula, n::Int)`

`n` random samples from a Gaussian copula `gc`
"""
function rand(gc::GaussCopula, n::Int)
  u = zeros(Float64, gc.n, n)
  x = zeros(Float64, gc.n, n)
  z = rand(MvNormal(zeros(Float64, gc.n), gc.Σ), n)
  for 𝑖 ∈ 1:gc.n
    u[𝑖,:] = cdf.(Ref(Normal()), z[𝑖,:])
    x[𝑖,:] = quantile.(Ref(gc.marginals[𝑖]), u[𝑖,:])
  end
  return x'
end

"""
`profit!(pl::PLInsurance, r_distr::Vector{Float64}, s::Real)`

 Updates `pl.profit`, where `r_distr` is the loss distribution
 and `s` is the risk free interest rate
"""
function profit!(pl::PLInsurance,
                 r_distr::Vector{Float64},
                 s::Real)
  pl.profit =
    (1+s) * pl.premium .- (1 - pl.ceded) * r_distr .- pl.costs
  return pl
end

"""
`profit!(pl::PLInvestments, r_distr::Vector{Float64}, s::Real)`

 Updates `pl.profit`, where `r_distr` is the investment result
 and `s` is the risk free interest rate. Only the investment
 return above `s` counts as profit.
"""
function profit!(pl::PLInvestments,
                 r_distr::Vector{Float64},
                 s::Real)
  pl.profit = (r_distr .- s) * (pl.invest_bop) .- pl.costs
  return pl
end

"""
`profit!(pl::PLTotal, pl_bu::Array{ProfitLoss},
  cap_init::Real, costs_fixed::Real, s::Real)`

 Updates `pl.profit`, where `cap_init` is the initial capital,
 `pl_bu` are the profit loss accounts of the business units,
 `costs_fixed` are the fixed costs, and `s` is the risk free
 interest rate.
"""
function profit!(pl::PLTotal, pl_bu::Array{ProfitLoss},
                 cap_init::Real, costs_fixed::Real, s::Real)
  fill!(pl.profit, 0.0)
  for  𝑝𝑙𝑏𝑢 ∈ pl_bu
    pl.profit .+= 𝑝𝑙𝑏𝑢.profit
  end
  pl.profit .+= (s * cap_init - costs_fixed)
  return pl
end

"""
`evaluate!(pl::ProfitLoss, α::Real)`

 Calculate expected profit, economic capital (expected shortfall
   at safety level `α`), and RORAC for `pl`
"""
function evaluate!(pl::ProfitLoss, α::Real)
  pl.profit_mean = mean(pl.profit)
  pl.eco_cap = es(-pl.profit, α)
  pl.rorac =
    pl.eco_cap < eps() ? NaN : pl.profit_mean / pl.eco_cap
end

"""
`initialize(insurance_input::DataFrame, invest_input::DataFrame,
  tau_kendall::Matrix{Real}, n_scen::Int)`

 Set up an insurance company
"""
function initialize(insurance_input::DataFrame,
                    invest_input::DataFrame,
                    tau_kendall::Matrix{Real},
                    n_scen::Int)
  n_bu = nrow(insurance_input) + 1
  bu = Array{BusinessUnit}(undef, n_bu)
  distr = Array{ContinuousUnivariateDistribution}(undef, n_bu)

  for 𝑖 ∈ insurance_input[:ctr]
    bu[𝑖] =
      BuInsurance(insurance_input[𝑖, :id],
                  insurance_input[𝑖, :name],
                  PLInsurance(insurance_input, 𝑖, n_scen, false),
                  PLInsurance(insurance_input, 𝑖, n_scen, true))
    lognorm_sd = sqrt(log(1 + insurance_input[𝑖,:var_coeff]^2 ))
    lognorm_mean =
      log(insurance_input[𝑖, :loss_ratio] * bu[𝑖].gross.premium) -
      0.5lognorm_sd^2
    distr[𝑖] = LogNormal(lognorm_mean, lognorm_sd)
  end

  bu[invest_input[1, :ctr]] =
    BuInvestments(invest_input[1, :id],
                  invest_input[1, :name],
                  bu[1:(n_bu - 1)],
                  invest_input[1, :cost_ratio],
                  invest_input[1, :init],
                  n_scen)
  distr[invest_input[1, :ctr]] =
    Normal(invest_input[1, :mean], invest_input[1, :sd])
  gc = GaussCopula(distr, convert(Array{Real, 2},
                                  sin.(π/2 * tau_kendall)))
  return bu, gc
end


"""
`project(ins_input::DataFrame, inv_input::DataFrame,
  tau_kendall::Matrix{Real}, n_scen::Int, α::Real, s::Real
  costs_fixed::Real)`

 Set up an insurance company and project its results
"""
function project(ins_input::DataFrame,
                 inv_input::DataFrame,
                 tau_kendall::Matrix{Real},
                 n_scen::Int,
                 α::Real,
                 s::Real,
                 costs_fixed::Real)

  bu, gc = initialize(ins_input, inv_input, tau_kendall, n_scen)
  n_bu = length(bu)

  rand_distr = rand(gc, n_scen)
  for 𝑖 ∈ 1:n_bu
    for 𝑔𝑟𝑜𝑠𝑠_𝑛𝑒𝑡 ∈ [bu[𝑖].gross, bu[𝑖].net]
      profit!(𝑔𝑟𝑜𝑠𝑠_𝑛𝑒𝑡, rand_distr[:,𝑖], s)
      evaluate!(𝑔𝑟𝑜𝑠𝑠_𝑛𝑒𝑡,α)
    end
  end
  total = Total(PLTotal(n_scen), PLTotal(n_scen))
  ## get easier access for the following for loop
  bu_gross = ProfitLoss[bu[𝑖].gross for 𝑖 ∈ 1:n_bu]
  bu_net = ProfitLoss[bu[𝑖].net for 𝑖 ∈ 1:n_bu]
  for (𝑔𝑛, 𝑏𝑢𝑔𝑛) ∈ [(total.gross, bu_gross),
                     (total.net, bu_net)]
    profit!(𝑔𝑛, 𝑏𝑢𝑔𝑛, bu[end].init, costs_fixed, s)
    evaluate!(𝑔𝑛,α)
  end


  return bu, total
end
