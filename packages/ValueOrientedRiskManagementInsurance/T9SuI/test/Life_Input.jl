## example insurer X Inc.

rfr = [0.01, 0.015, 0.018, 0.02, 0.021] # risk free forward rate

## example company X-AG =========================================
T = 5

df_sub_debt = DataFrame(
  name = [:sub],
  nominal = [100.],              ## nominal value of loan
  t_init = [-1],                 ## time loan has been taken out
  t_mat = [5],                   ## maturity of loan
  coupon = [7.5])                ## yearly interest coupon

sx_fac = 0.9
β = DataFrame( ## profile insurance contract
              qx = fill(1.0, T),         ## death ben rel ins sum
              sx = cumsum(fill(sx_fac, T)), ## lapse ben rel prem
              px = [fill(0.0, T-1); 1],  ## life ben  rel ins sum
              prem = fill(1.0, T))       ## premium payments

prob_price = DataFrame( ## biometric probabilities
                       qx = 0.001 .+ collect(0:(T-1)) * 0.0001,
                       sx = fill(0.1, T)
                       )
rfr_price = fill(0.005, T)        ## discount rate
λ_price =  DataFrame(  ## cost profile
                     boy = [0.05; fill(0.0, T-1)], ## costs boy
                     eoy = fill(0.06, T),   ## costs end of year
                     infl = fill(0.01, T))  ## cost inflation

## best estimate assumptions ------------------------------------

## capital market -----------------------------------------------
proc_stock = Stock(1.0,                    ## initial value x_0
                   cumprod(fill(1.07, T)),  ## values x
                   0.05)                  ## yield during t_0

proc_rfr = RiskFreeRate(rfr[1:T],     ## values x
                        0.02)        ## yield during t_0

## investments --------------------------------------------------
general_cost_infl = 0.02

df_cash = DataFrame(
  name = [:bank_1, :bank_2],
  mv_0 = [800., 200],
  lgd = [0.8, 0.5],
  rating = ["BBB", "A"])

df_stock = DataFrame(
  name = [:stock_index],
  mv_0 = [1500.],
  lgd = [0.0],     ## dummy entry to simplify dfalloc below
  rating = "na")   ## dummy entry to simplify dfalloc below

λ_invest = Dict{Symbol, DataFrame}()
merge!(λ_invest,
       Dict{Symbol, DataFrame}(
         :IGCash => DataFrame(rel = fill(0.005, T),
                              abs = fill(0.5, T),
                              infl_rel = zeros(Float64, T),
                              infl_abs =
                                fill(general_cost_infl, T)),
         :IGStock => DataFrame(rel = fill(0.01, T),
                               abs = fill(2.0, T),
                               infl_rel = zeros(Float64, T),
                               infl_abs =
                                 fill(general_cost_infl, T))))



eq2type = Dict{Symbol,Symbol}(:stock_index => :type_1)

## initial target allocation == current relative allocation -----
mv_total_0 = sum(df_cash[:mv_0]) + sum(df_stock[:mv_0])

dfalloc(dur, df, mv_total_0, sp_2_cqs) =
  Alloc(convert(Array, df[:name]),
        vcat(sum(df[:mv_0]) / mv_total_0,
             zeros(Float64, dur - 1)),
        vcat(vec(df[:mv_0] / sum(df[:mv_0]))',
             zeros(Float64, dur-1, nrow(df))),
        convert(Array, df[:lgd]),
        Symbol[sp_2_cqs[df[𝑖,:rating]] for 𝑖 ∈ 1:nrow(df)])

allocs = Dict{Symbol, Alloc}()
merge!(allocs,
       Dict{Symbol, Alloc}(
         :IGCash => dfalloc(T, df_cash, mv_total_0, sp_2_cqs),
         :IGStock => dfalloc(T, df_stock, mv_total_0, sp_2_cqs)))

## Portfolio ----------------------------------------------------
df_portfolio = DataFrame(
  t_start =           [  -4,   -3,   -2,   -1,    0],
  n =                 [  60,   70,   80,   90,  100],
  ins_sum =           [10.0, 10.0, 10.0, 10.0, 10.0],
  bonus_rate_hypo =   [0.025, 0.025, 0.025, 0.025, 0.025],
  sx_be_fac =         [0.90, 0.95, 0.94, 0.97, 1.00],
  pension_contract =  [false, false, false, false, false])

## biometric probabilities
## initial estimate at start of  projection, based on
## capital market and bonus declaration at time t_0
prob_be =  DataFrame(qx = prob_price[:qx] .- 0.0001,
                     sx = 0.1 * reverse(collect(0:(T-1)))/(T-1))

## cost profile
λ_be = DataFrame(
  boy = [0.05; fill(0.0, T-1)], ## costs boy
  eoy = fill(0.02, T))          ## costs end of year

## cost inflation
## we define a be cost inflation vector for each portfolio tranche,
## starting with year t_0 + 1
cost_infl_be = Array{Vector{Float64}}(undef, nrow(df_portfolio))
for 𝑑 ∈ 1:nrow(df_portfolio)
  cost_infl_be[𝑑] =
    fill(general_cost_infl, T + df_portfolio[𝑑, :t_start])
end

## dynamics -----------------------------------------------------
bonus_factor = 0.9
quota_surp =  2500/1058-1 ## approx value at beginning

## cashflow projection ------------------------------------------
tax_rate = 0.3
tax_credit_0 = 7.0

s2_op =
  Dict{Symbol, Float64}(:prem_earned => 1200.0,
                        :prem_earned_prev => 800.0,
                        :cost_ul => 0.0,
                        :tp => 0.0)
