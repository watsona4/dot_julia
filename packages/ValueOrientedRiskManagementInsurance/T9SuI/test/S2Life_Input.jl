using Test

## General ######################################################
sp_2_cqs = Dict{AbstractString, Symbol}("AAA" => :cqs_0,
                                 "AA" => :cqs_1,
                                 "A" => :cqs_2,
                                 "BBB" => :cqs_3,
                                 "BB" => :cqs_4,
                                 "other" => :cqs_5,
                                 "na" => :na)

## SCR Parameters ###############################################
## SCR BSCR =====================================================
ds2 =
  Dict{Symbol, Any}(:corr => [1.00  0.25  0.25  0.25  0.25;
                               0.25  1.00  0.25  0.25  0.50;
                               0.25  0.25  1.00  0.25  0.00;
                               0.25  0.25  0.25  1.00  0.00;
                               0.25  0.50  0.00  0.00  1.00],
                     :mdl => [:S2Mkt, :S2Def, :S2Life,
                              :S2Health, :S2NonLife],
                     :coc => 0.06)

## SCR Op =======================================================
ds2_op = Dict{Symbol, Float64}(:bscr => 0.3,
                               :cost => 0.25,
                               :prem => 0.04,
                               :prem_py => 1.2,
                               :tp => 0.0045)

## SCR Mkt ======================================================
## The indices 21, 31, 41, 12, 13, 14 need to be adjusted
corr_mkt_raw =
  [1.00  0.00  0.00  0.00  0.25  0.00;
   0.00  1.00  0.75  0.75  0.25  0.00;
   0.00  0.75  1.00  0.50  0.25  0.00;
   0.00  0.75  0.50  1.00  0.25  0.00;
   0.25  0.25  0.25  0.25  1.00  0.00;
   0.00  0.00  0.00  0.00  0.00  1.00]

ind_adj = Array{Vector{Int}}(undef, 0)
push!(ind_adj, [1,2], [1,3], [1,4], [2,1], [3,1], [4,1])

function corrmkt(raw::Matrix, ind_adj, updown::Symbol)
  a = (updown == :up ? 0.0 : 0.5)
  corr = deepcopy(raw)
  for 𝑝𝑎𝑖𝑟 ∈ ind_adj
    corr[𝑝𝑎𝑖𝑟[1], 𝑝𝑎𝑖𝑟[2]]= a
  end
  return corr
end

ds2_mkt =
  Dict{Symbol, Any}(:raw => corr_mkt_raw,
                    :adj => ind_adj,
                    :corr => corrmkt,
                    :mdl => [:S2MktInt, :S2MktEq, :S2MktProp,
                             :S2MktSpread, :S2MktFx, :S2MktConc])

## SCR Mkt Int --------------------------------------------------
## only first 9 deltas, SCR.5.25
δ_down =
  [-0.75, -0.65, -0.56, -0.50, -0.46, -0.42, -0.39, -0.36, -0.33]
δ_up =
  [ 0.70,  0.70,  0.64,  0.59,  0.55,  0.52,  0.49,  0.47,  0.44]

ds2_mkt_int =
  Dict{Symbol, Any}(:shock =>
                      Dict{Symbol, Any}(:spot_up => δ_up,
                                        :spot_down => δ_down),
                    :spot_up_abs_min => 0.01)

## SCR Mkt Eq ---------------------------------------------------
eq_shock_raw_1, eq_shock_raw_2 = -0.39, -0.49
eq_adj_sym = -0.075
eq_shock =
  Dict{Symbol, Float64}(:type_1 => eq_shock_raw_1 + eq_adj_sym,
                        :type_2 => eq_shock_raw_2 + eq_adj_sym)

ds2_mkt_eq = Dict{Symbol, Any}(:shock => eq_shock,
                               :corr => [1  0.75;  0.75  1])

## SCR Mkt all --------------------------------------------------
ds2_mkt_all =
  Dict{Symbol, Dict{Symbol, Any}}(:mkt => ds2_mkt,
                                  :mkt_int => ds2_mkt_int,
                                  :mkt_eq => ds2_mkt_eq)

## SCR Def ======================================================
ds2_def = Dict{Symbol, Any}(:corr => [1.00  0.75; 0.75  1.00])

## SCR Def Type 1  ----------------------------------------------
df_def_1 =
  DataFrame(quant = ["ProbGD"],
            cqs_0 =      [0.00002],
            cqs_1 =      [0.00010],
            cqs_2 =      [0.00050],
            cqs_3 =      [0.00240],
            cqs_4 =      [0.01200],
            cqs_5 =      [0.04200],
            cqs_6 =      [0.04200],
            cqs_unrat =  [0.04200])
df_def_scr =
  DataFrame(range = [:low, :medium, :high],
            multiplier = [3.0, 5.0, NaN],
            threshold_upper = [0.07, 0.20, 1.00])

ds2_def_1 = Dict{Symbol, Any}(:prob => df_def_1,
                              :scr_par => df_def_scr)

## SCR Def all  -------------------------------------------------
ds2_def_all = Dict{Symbol, Any}(:def => ds2_def,
                                :def_1 => ds2_def_1)

## SCR Life =====================================================
ds2_life =
  Dict{Symbol, Any}(
  :corr => [ 1.00  -0.25   0.25   0.00   0.25   0.00   0.25;
             -0.25   1.00   0.00   0.25   0.25   0.25   0.00;
             0.25   0.00   1.00   0.00   0.50   0.00   0.25;
             0.00   0.25   0.00   1.00   0.50   0.00   0.25;
             0.25   0.25   0.50   0.50   1.00   0.50   0.25;
             0.00   0.25   0.00   0.00   0.50   1.00   0.00;
             0.25   0.00   0.25   0.25   0.25   0.00   1.00],
   :mdl => [:S2LifeQx, :S2LifePx, :S2LifeMorb, :S2LifeSx,
            :S2LifeCost,  :S2LifeRevision,  :S2LifeCat])

@test ds2_life[:corr] == ds2_life[:corr]'

## SCR Life Mort ------------------------------------------------
ds2_life_qx = Dict{Symbol, Any}(:shock => Dict(:qx => 0.15))

## SCR Life Long ------------------------------------------------
ds2_life_px = Dict{Symbol, Any}(:shock => Dict(:px => -0.20))

## SCR Life Lapse -----------------------------------------------
ds2_life_sx =
  Dict{Symbol, Any}(:shock => Dict(:sx_up => 0.5,
                                   :sx_down => -0.5,
                                   :sx_mass_other => 0.4,
                                   :sx_mass_pension => 0.7),
                    :shock_param =>
                      Dict(:sx_down_threshold => -0.2))
## SCR Life Expense ---------------------------------------------
ds2_life_cost =
  Dict{Symbol, Any}(:shock => Dict(:cost => 0.10),
                    :shock_param => Dict(:infl => 0.01))

## SCR Life Cat -------------------------------------------------
ds2_life_cat = Dict{Symbol, Any}(:shock => Dict(:cat => 0.15))

## SCR all ======================================================
ds2_life_all = Dict{Symbol, Any}(:life => ds2_life,
                                 :life_qx => ds2_life_qx,
                                 :life_px => ds2_life_px,
                                 :life_sx => ds2_life_sx,
                                 :life_cost => ds2_life_cost,
                                 :life_cat => ds2_life_cat)
