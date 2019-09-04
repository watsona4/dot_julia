using ValueOrientedRiskManagementInsurance

using Distributions
using DataFrames

include("ECModel_Input.jl")

println("Start ECModel ...")
#################################################################
"Create DataFrame from information on business units and total"
function getdf(bu, total)
  df =  DataFrame(BU = Array{Symbol}(undef, 0),
                  GrossNet = Array{Symbol}(undef, 0),
                  CumProb = Array{Float64}(undef, 0),
                  Profit = Array{Real}(undef, 0))

  for 𝑖 ∈ 1:length(bu)
    append!(df, DataFrame(
      BU = fill!(Array{Symbol}(undef, n_scen), bu[𝑖].id),
      GrossNet = fill!(Array{Symbol}(undef, n_scen), :gross),
      CumProb = real(collect(1:n_scen)) /  n_scen,
      Profit = sort(bu[𝑖].gross.profit)))
    append!(df, DataFrame(
      BU = fill!(Array{Symbol}(undef, n_scen), bu[𝑖].id),
      GrossNet = fill!(Array{Symbol}(undef, n_scen), :net),
      CumProb = real(collect(1:n_scen)) /  n_scen,
      Profit = sort(bu[𝑖].net.profit)))
  end
  append!(df, DataFrame(
    BU = fill(:total, n_scen),
    GrossNet = fill(:gross, n_scen),
    CumProb = real(collect(1:n_scen)) /  n_scen,
    Profit = sort(total.gross.profit)))
  append!(df, DataFrame(
    BU = fill(:total, n_scen),
    GrossNet = fill(:net, n_scen),
    CumProb = real(collect(1:n_scen)) /  n_scen,
    Profit = sort(total.net.profit)))
  append!(df, DataFrame(
    BU = fill(:risk_cap_total, 4),
    GrossNet = [:gross, :gross, :net, :net],
    CumProb = real([0., 1., 0., 1.]),
    Profit = convert(Vector{Real},
                     [fill(-total.gross.eco_cap, 2);
                      fill(-total.net.eco_cap,2)])))
  return df
end

"Construct efficient frontier"
function effline(x₀, y₀, a, y_min, y_max)
  x_min = x₀ + (y_min-y₀) / a
  x_max = x₀ + (y_max-y₀) / a
  return hcat([x_min, x₀, x_max], [y_min, y₀, y_max])
end

eff(x₀, y₀, a, x) = y₀ + a * (x-x₀)

"Equalizing risk premium"
function riskprice(ins_input::DataFrame,
                   inv_inout::DataFrame,
                   tau_kendall::Matrix{Real},
                   n_scen::Int,
                   α::Real,
                   s::Real,
                   costs_fixed::Real,
                   Δp_min::Real,
                   Δp_max::Real,
                   Δp_init::Real)
  ins = deepcopy(ins_input)
  i_max = 50 ## max 50 iterations
  rorac_gross_i = zeros(Real, i_max)
  rorac_gross_f = zeros(Real, i_max)
  Δp = zeros(Real, i_max + 1)
  Δp_tol  = 1e-5      ## break criterion : minimum price change
  row_l = ins[ins[:name] .== "Liability", :ctr][1,1]
  row_f = ins[ins[:name] .== "Fire", :ctr][1,1]
  if (row_l != ins[row_l, :ctr]) | (row_f != ins[row_f, :ctr])
    error("row_l ($row_l) or row_f ($row_f) does not match.")
  end
  n_steps = 0
  Δp[1] = Δp_init
  for 𝑖 ∈ 1:i_max
    Random.seed!(seed)
    ins[row_l, :premium] =
      ins_input[row_l, :premium] * (1 + Δp[𝑖])
    ins[row_f, :premium] =
      ins_input[row_f, :premium] -
      ins_input[row_l, :premium] * Δp[𝑖]
    fac_i = ins_input[row_l, :premium] / ins[row_l, :premium]
    fac_f = ins_input[row_f, :premium] / ins[row_f, :premium]
    ins[row_l, :loss_ratio] =
      ins_input[row_l, :loss_ratio] * fac_i
    ins[row_f, :loss_ratio] =
      ins_input[row_f, :loss_ratio] * fac_f
    ins[row_l, :cost_ratio] =
      ins_input[row_l, :cost_ratio] * fac_i
    ins[row_f, :cost_ratio] =
      ins_input[row_f, :cost_ratio] * fac_f
    ins[row_l, :re_costs] = ins_input[row_l, :re_costs] * fac_i
    ins[row_f, :re_costs] = ins_input[row_f, :re_costs] * fac_f

    bu, total =
      project(ins, inv_input, tau_kendall, n_scen, α, s,
              costs_fixed)
    rorac_gross_i[𝑖] = bu[row_l].gross.rorac
    rorac_gross_f[𝑖] = bu[row_f].gross.rorac

    if Δp_max - Δp_min < Δp_tol
      n_steps = 𝑖
      break
    end
    if rorac_gross_i[𝑖] < rorac_gross_f[𝑖]
      Δp_min = Δp[𝑖]
    else
      Δp_max = Δp[𝑖]
    end
    Δp[𝑖+1] = (Δp_min + Δp_max) / 2
  end
  return ins, Δp[1:n_steps],
         rorac_gross_i[1:n_steps], rorac_gross_f[1:n_steps]
end


"Optimizing Capitalization"
function optcap(ins_input::DataFrame,
                inv_input::DataFrame,
                tau_kendall::Matrix{Real},
                n_scen::Int,
                α::Real,
                s::Real,
                cost_fixed::Real)
  inv = deepcopy(inv_input)
  i_max = 8
  invest_init = inv[1,:init] .- collect(0:(i_max-1)) * 100.
  profit_net = zeros(Real, i_max)
  ec_net = zeros(Real, i_max)
  rorac_net = zeros(Real, i_max)
  roc_net = zeros(Real, i_max)

  for 𝑖 ∈ 1:i_max
    Random.seed!(seed)
    inv[1,:init] = invest_init[𝑖]
    bu, total =
      project(ins_input, inv, tau_kendall,
              n_scen, α, s, cost_fixed)
    profit_net[𝑖] = total.net.profit_mean
    ec_net[𝑖] = total.net.eco_cap
    rorac_net[𝑖] = total.net.rorac
    roc_net[𝑖] = total.net.profit_mean / invest_init[𝑖]
  end
  inv_init_opt = 0
  ec_net_opt = 0
  profit_net_opt = 0
  i_opt = 0
  ## only works if invest_init[1] >  ec_cap_net[1]
  for 𝑖 ∈ 1:i_max
    if invest_init[𝑖] < ec_net[𝑖]
      inv_init_opt = invest_init[𝑖-1]
      ec_net_opt = ec_net[𝑖-1]
      profit_net_opt = profit_net[𝑖-1]
      i_opt = 𝑖-1
      break
    end
  end
  inv[1, :init] = inv_init_opt
  return inv, i_opt, invest_init, ec_net, rorac_net, roc_net,
  inv_init_opt, ec_net_opt, profit_net_opt
end

"Optimizing Fire Reinsurance"
function optrefire(ins_input::DataFrame,
                   inv_input::DataFrame,
                   tau_kendall::Matrix{Real},
                   n_scen::Int,
                   α::Real,
                   s::Real,
                   cost_fixed::Real)
  ins = deepcopy(ins_input)
  n_points = 21
  points = zeros(Real, n_points+1, 4)

  i_opt = 0
  ceded_opt = 0
  profit_net_opt = 0
  ec_net_opt = 0
  rorac_net_opt = 0
  ceded = zeros(Real, n_points)
  profit_net = zeros(Real, n_points)
  ec_net = zeros(Real, n_points)
  rorac_net = zeros(Real, n_points)
  row_f = ins[ins[:name] .== "Fire", :ctr][1,1]
  if row_f != ins[row_f, :ctr]
    error("row_f ($row_f) does not match.")
  end

  for 𝑖 ∈ 1:n_points
    Random.seed!(seed)
    ceded[𝑖] = (𝑖-1) / (n_points-1)
    ins[row_f, :re_ceded] = ceded[𝑖]
    bu, total =
      project(ins, inv_input, tau_kendall,
      n_scen, α, s, cost_fixed)
    ec_net[𝑖] = total.net.eco_cap
    profit_net[𝑖] = total.net.profit_mean
    rorac_net[𝑖] = total.net.rorac
    if rorac_net[𝑖] > rorac_net_opt
      ceded_opt = ceded[𝑖]
      profit_net_opt = profit_net[𝑖]
      ec_net_opt = ec_net[𝑖]
      rorac_net_opt = rorac_net[𝑖]
      i_opt = 𝑖
    end
  end
  ins[row_f, :re_ceded] = ceded_opt
  return ins, ceded, profit_net, ec_net,
  i_opt, ceded_opt, profit_net_opt, ec_net_opt, rorac_net_opt
end

"Optimizing Reinsurance RAROC no constraints"
function optreraroc(ins_input::DataFrame,
                    inv_input::DataFrame,
                    tau_kendall::Matrix{Real},
                    n_scen::Int,
                    α::Real,
                    s::Real,
                    cost_fixed::Real,
                    n_points::Int)
  ins = deepcopy(ins_input)
  unif = Uniform()
  ceded = Array{Real}(undef, nrow(ins), n_points)
  profit_net = Array{Real}(undef, n_points)
  ec_net = Array{Real}(undef, n_points)
  rorac_net = Array{Real}(undef, n_points)
  i_opt, profit_net_opt, ec_net_opt, rorac_net_opt =
    1, 0.0, 0.0, 0.0

  for 𝑏 ∈ 1:nrow(ins)
    ceded[𝑏,:] = rand(unif, n_points)
  end
  for 𝑖 ∈ 1:n_points
    Random.seed!(seed)
    for 𝑏 ∈ 1:nrow(ins)
      ins[𝑏, :re_ceded] = ceded[𝑏, 𝑖]
    end
    bu, total =
      project(ins, inv_input, tau_kendall,
              n_scen, α, s, cost_fixed)
    profit_net[𝑖] = total.net.profit_mean
    ec_net[𝑖] = total.net.eco_cap
    rorac_net[𝑖] = total.net.rorac
    if rorac_net[𝑖] > rorac_net_opt
      i_opt = 𝑖
      profit_net_opt = profit_net[𝑖]
      ec_net_opt = ec_net[𝑖]
      rorac_net_opt = rorac_net[𝑖]
    end
  end
  for 𝑏 ∈ 1:nrow(ins)
    ins[𝑏, :re_ceded] = ceded[𝑏, i_opt]
  end
  return ins, profit_net, ec_net, rorac_net,
  profit_net_opt, ec_net_opt, rorac_net_opt
end

"Optimizing Reinsurance EVA no constraints"
function optreeva(ins_input::DataFrame,
                  inv_input::DataFrame,
                  tau_kendall::Matrix{Real},
                  n_scen::Int,
                  α::Real,
                  s::Real,
                  cost_fixed::Real,
                  n_points::Int,
                  hurdle::Real)
  ins = deepcopy(ins_input)
  unif = Uniform()
  ceded = Array{Real}(undef, nrow(ins), n_points)
  avg_ceded = Array{Real}(undef, n_points)
  eva_net = Array{Real}(undef, n_points)
  i_opt = 0
  avg_ceded_opt  = 0.0
  eva_net_opt = 0.0

  for 𝑏 ∈ 1:nrow(ins)
    ceded[𝑏,:] = rand(unif, n_points)
  end
  for 𝑖 ∈ 1:n_points
    Random.seed!(seed)
    for 𝑏 ∈ 1:nrow(ins)
      ins[𝑏, :re_ceded] = ceded[𝑏, 𝑖]
    end
    bu, total =
      project(ins, inv_input, tau_kendall,
              n_scen, α, s, cost_fixed)
    avg_ceded[𝑖] =
      ins[:re_ceded] ⋅ ins[:premium] /sum(ins[:premium])
    eva_net[𝑖] =
      total.net.profit_mean - hurdle * total.net.eco_cap
    if eva_net[𝑖] > eva_net_opt
      i_opt = 𝑖
      avg_ceded_opt = avg_ceded[𝑖]
      eva_net_opt = eva_net[𝑖]
    end
  end
  for 𝑏 ∈ 1:nrow(ins)
    ins[𝑏, :re_ceded] = ceded[𝑏, i_opt]
  end
  return ins, avg_ceded, eva_net, avg_ceded_opt, eva_net_opt
end

"Optim. reins. RAROC prescribed average reinsurance quote"
function optre(ins_input::DataFrame,
               inv_input::DataFrame,
               tau_kendall::Matrix{Real},
               n_scen::Int,
               α::Real,
               s::Real,
               cost_fixed::Real,
               n_points::Int,
               avg_ceded::Real)
  ins = deepcopy(ins_input)
  unif = Uniform()
  ceded = Array{Real}(undef, nrow(ins), n_points)
  random =  Array{Real}(undef, nrow(ins), n_points)
  profit_net = Array{Real}(undef, n_points)
  ec_net = Array{Real}(undef, n_points)
  rorac_net = Array{Real}(undef, n_points)
  i_opt, profit_net_opt, ec_net_opt, rorac_net_opt =
    0, 0.0, 0.0, 0.0

  prem_gross = sum(ins_input[:, :premium])
  for 𝑖 ∈ 1:n_points
    rand_vector_admissable = false
    while !rand_vector_admissable
      random[:,𝑖] = rand(unif, nrow(ins))
      prem_temp = random[:,𝑖] ⋅ ins_input[:, :premium]
      for 𝑏 ∈ 1:nrow(ins)
        ceded[𝑏, 𝑖] =
          avg_ceded * random[𝑏, 𝑖] * prem_gross / prem_temp
      end
      # We cannot cede more than 100%
      rand_vector_admissable =
        all(ceded[:,𝑖] .<= ones(nrow(ins)))
    end
  end
  for 𝑖 ∈ 1:n_points
    Random.seed!(seed)
    # for b = 1:nrow(ins)
    #   ceded[b, i] =
    #     avg_ceded * random[b, i] * prem_gross / prem_temp
    #   ins[b, :re_ceded] = ceded[b, i]
    # end
    ins[:, :re_ceded] = ceded[:, 𝑖]
    bu, total =
      project(ins, inv_input, tau_kendall,
              n_scen, α, s, cost_fixed)
    profit_net[𝑖] = total.net.profit_mean
    ec_net[𝑖] = total.net.eco_cap
    rorac_net[𝑖] = total.net.rorac
    if rorac_net[𝑖] > rorac_net_opt
      i_opt = 𝑖
      profit_net_opt = profit_net[𝑖]
      ec_net_opt = ec_net[𝑖]
      rorac_net_opt = rorac_net[𝑖]
    end
  end
  ins[:, :re_ceded] = ceded[:, i_opt]
  return ins, ceded, profit_net, ec_net, rorac_net,
  profit_net_opt, ec_net_opt, rorac_net_opt
end

#################################################################
row_f =
  insurance_input[insurance_input[:name] .== "Fire", :ctr][1,1]
row_l =
  insurance_input[insurance_input[:name] .==
  "Liability", :ctr][1,1]
row_t =
  insurance_input[insurance_input[:name] .== "Theft", :ctr][1,1]

pl_fire_exact_gross =
  (1 + s -
     insurance_input[row_f, :loss_ratio] -
     insurance_input[row_f, :cost_ratio]) *
  insurance_input[row_f, :premium]


pl_cap_rf = s * invest_input[1, :init]
pl_diff = pl_cap_rf - costs_fixed


Random.seed!(seed) ## fix random seed for repeatable results
bu, total =
  project(insurance_input, invest_input, tau_kendall,
          n_scen, α, s, costs_fixed)

n_bu = length(bu)
abbrevs = AbstractString[string(bu[𝑏].name[1]) for 𝑏 ∈ 1:n_bu]

diff_ec_gross =
  total.gross.eco_cap -
  sum([bu[𝑖].gross.eco_cap  for 𝑖 ∈ 1:length(bu)])
diff_ec_net =
  total.net.eco_cap -
  sum([bu[𝑖].net.eco_cap for 𝑖 ∈ 1:length(bu)])

## BU results
profit_gross = Real[bu[𝑖].gross.profit_mean for 𝑖 ∈ 1:length(bu)]
profit_net = Real[bu[𝑖].net.profit_mean for 𝑖 ∈ 1:length(bu)]

ec_gross = Real[bu[𝑖].gross.eco_cap for 𝑖 ∈ 1:length(bu)]
ec_net = Real[bu[𝑖].net.eco_cap for 𝑖 ∈ 1:length(bu)]

rorac_gross = Real[bu[𝑖].gross.rorac for 𝑖 ∈ 1:length(bu)]
rorac_net = Real[bu[𝑖].net.rorac for 𝑖 ∈ 1:length(bu)]

x = hcat(profit_gross, ec_gross, ec_net)


##  Portfolio Optimizations #####################################

ins_input = deepcopy(insurance_input)
inv_input = deepcopy(invest_input)

## Risk-Adjusted Price-Setting ==================================
println("Risk-Adjusted Price-Setting ...")
Δp_min = 0.0
Δp_max = 0.05
Δp_init = 0.0

ins_input_rp, Δp, rorac_price_gross_i, rorac_price_gross_f =
  riskprice(ins_input, inv_input, tau_kendall, n_scen, α, s,
            costs_fixed, Δp_min, Δp_max, Δp_init)

Random.seed!(seed)
bu_rp, total_rp =
  project(ins_input_rp, invest_input, tau_kendall,
          n_scen, α, s, costs_fixed)

## Optimizing Capitalization ====================================
println("Optimizing Capitalization ... ")
inv_input_oc, i_oc_opt, invest_init_oc, ec_net_oc, rorac_net_oc,
roc_net_oc, inv_init_oc_opt, ec_net_oc_opt, profit_net_oc_opt =
  optcap(ins_input_rp, inv_input, tau_kendall,
         n_scen, α, s, costs_fixed)

Random.seed!(seed)
bu_oc, total_oc =
  project(ins_input_rp, inv_input_oc, tau_kendall,
          n_scen, α, s, costs_fixed)

## Optimizing Fire Reinsurance ==================================
println("Optimizing Fire Reinsurance ...")
ins_input_ofr, ceded_ofr, profit_net_ofr, ec_net_ofr,
i_ofr, ceded_ofr_opt, profit_net_ofr_opt, ec_net_ofr_opt,
rorac_net_ofr_opt =
  optrefire(ins_input_rp, inv_input_oc, tau_kendall, n_scen, α,
            s, costs_fixed)

## Optimizing Reinsurance =======================================

## Optimizing Reinsurance RAROC no constraints ==================
println("Optimizing Reinsurance RAROC no constraints ... ")

ins_input_orraroc, profit_net_orraroc, ec_net_orraroc,
rorac_net_orraroc, profit_net_orraroc_opt, ec_net_orraroc_opt,
rorac_net_orraroc_opt =
  optreraroc(ins_input_ofr, inv_input_oc, tau_kendall,
             n_scen, α, s, costs_fixed, n_cloud)

ec_min = minimum(ec_net_orraroc)
p_min = findfirst( (in)(ec_min), ec_net_orraroc)

## Optimizing Reinsurance EVA no constraints ====================
println("Optimizing Reinsurance EVA no constraints ... ")

ins_input_oreva, avg_ceded_oreva, eva_net_oreva,
avg_ceded_opt_oreva, eva_net_opt_oreva =
  optreeva(ins_input_ofr, inv_input_oc, tau_kendall, n_scen,
           α,  s, costs_fixed, n_cloud, hurdle)

avg_ceded_ofr =
  ins_input_ofr[:re_ceded] ⋅ ins_input_ofr[:premium] /
  sum(ins_input_ofr[:premium])
eva_net_ofr = profit_net_ofr_opt - hurdle * ec_net_ofr_opt


## Optim. Reins. RAROC prescribed average reinsurance quote =====
println("Optim. Reins. RAROC prescr. average reins. quote ...")

ins_input_or, ceded_or, profit_net_or, ec_net_or, rorac_net_or,
profit_net_or_opt, ec_net_or_opt, rorac_net_or_opt =
  optre(ins_input_ofr, inv_input_oc, tau_kendall, n_scen,
        α,  s, costs_fixed, n_cloud, avg_ceded_ofr)

Random.seed!(seed)
bu_oc, total_oc =
  project(ins_input_or, inv_input_oc, tau_kendall,
          n_scen, α, s, costs_fixed)

## Other levels of confidence ===================================
println("Other levels of confidence ...")

Random.seed!(seed)
bu_final, total_final =
  project(ins_input_or, inv_input_oc, tau_kendall,
          n_scen, α, s, costs_fixed)

var_α = [0.5, 0.75, 0.9, 0.99]
var_eco_cap = [es(-total_final.net.profit, 𝛽) for 𝛽 in var_α]

print("Mean total gross profit:      ")
println(round(total.gross.profit_mean, digits = 2))
print("Mean total net profit:        ")
println(round(total.net.profit_mean, digits = 2))
print("Total gross economic capital: ")
println(round(total.gross.eco_cap, digits = 2))
print("Total net economic capital:   ")
println(round(total.net.eco_cap, digits = 2))
print("Total gross RORAC:            ")
println(round(total.gross.rorac, digits = 2))
print("Total net RORAC:              ")
println(round(total.net.rorac, digits = 2))

print("Risk adj. pricing, fire loss ratio     : ")
println(round(ins_input_rp[1, :loss_ratio], digits = 4))
print("Risk adj. pricing, liability loss ratio: ")
println(round(ins_input_rp[2, :loss_ratio], digits = 4))
print("Risk adj. pricing, theft loss ratio:     ")
println(round(ins_input_rp[3, :loss_ratio], digits = 4))

print("Optimal capital, net RORAC:  ")
println(round(ins_input_rp[3, :loss_ratio], digits = 4))

print("Optimal product mix with quota constraint, net RORAC:  ")
println(round(rorac_net_or_opt, digits = 4))

#################################################################
println("End ECModel \n")
