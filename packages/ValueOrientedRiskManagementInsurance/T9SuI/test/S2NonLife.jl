using ValueOrientedRiskManagementInsurance

using Distributions
using DataFrames

include("S2NonLife_Input.jl")

#################################################################
println("Start S2NonLife.jl")

lobs = Array{NLLob}(undef, 0)

for lob in select_lob_names
  push!(lobs, NLLob(df_lobs[df_lobs[:name] .== lob, :],
                    convert(Array, β_raw[lob]),
                    rf,
                    corr_prem_res, df_lobs_prem_risk))
end

## premium reserve risk #########################################
scr_prem_res = 3 * premrestotalsd(lobs, corr_lob)[1]
scr_lapse = 0.0

## catastrophe risk #############################################
## proportional reinsurance seems to be ignored for cat scr

## natural catastrophe risk -------------------------------------
scr_cat_nat = 0.0   ## no natural catastrophe risk in portfolio

## man-made catastrophe risk ------------------------------------
## only fire risk and liability risk in "man-made" portfolio

## fire
scr_cat_fire = sum(cat_fire_is) ## no risk management mechanisms

## liability
#prem_liab_vec = Array{Float64}(undef, nrow(df_cat_liability))
scr_cat_liab_vec = Array{Float64}(undef, nrow(df_cat_liability))
#cat_liab_grp = Array{Int}(undef, 0)
for 𝑙𝑜𝑏 ∈ lobs
  if 𝑙𝑜𝑏.name == :liability
    prem_liab_vec = 𝑙𝑜𝑏.prem_gross_cy * cat_liability_mix
    global scr_cat_liab_vec =
      convert(Array,
              prem_liab_vec .* df_cat_liability[:,:f_liab])
#    for 𝑖 ∈ 1:length(prem_liab_vec)
#      if prem_liab_vec[𝑖] > 0
#        push!(cat_liab_grp, 𝑖)
#      end
#    end
  end
end
scr_cat_liab =
  sqrt(scr_cat_liab_vec' * corr_liab * scr_cat_liab_vec)[1,1]

## total man-made catastrophe risk ------------------------------
scr_cat_man_made_vec = [scr_cat_fire, scr_cat_liab]
scr_cat_man_made =
  sqrt(scr_cat_man_made_vec ⋅ scr_cat_man_made_vec)

## other catastrophe risk ---------------------------------------
scr_cat_other = 0.0

## catastrophe risk for non-prop reinsurance --------------------
scr_cat_nprop = 0.0  ## XYZ does not act as reinsurer

## total catastrophe risk ---------------------------------------
scr_cat = sqrt((scr_cat_nat + scr_cat_nprop)^2 +
                 scr_cat_man_made^2 +
                 scr_cat_other^2)

## Total SCR ####################################################
scr_nl_vec = [scr_prem_res, scr_lapse, scr_cat]
scr_nl = sqrt(scr_nl_vec ⋅ (corr_scr * scr_nl_vec))

## main results #################################################
println("scr_prem_risk        :  $(round(scr_prem_res,
                                         digits = 2))")
println("scr_lapse            :  $(round(scr_lapse,
                                         digits = 2))")
println("scr_cat_man_made_fire:  $(round(scr_cat_fire,
                                         digits = 2))")
println("scr_cat_man_made_liab:  $(round(scr_cat_liab,
                                         digits = 2))")
println("scr_cat_man_made     :  $(round(scr_cat_man_made,
                                         digits = 2))")
println("scr_cat_other        :  $(round(scr_cat_other,
                                         digits = 2))")
println("scr_cat_nprob        :  $(round(scr_cat_nprop,
                                         digits = 2))")
println("scr_cat              :  $(round(scr_cat, digits = 2))")
println("scr_total            :  $(round(scr_nl, digits = 2))")

println("End S2NonLife.jl")
