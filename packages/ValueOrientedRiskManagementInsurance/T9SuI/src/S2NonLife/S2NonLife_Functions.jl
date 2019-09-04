export  premrestotalsd
using Distributions

"Constructs line of business & calculates statistical parameters"
function NLLob(lob::DataFrame,
               β_raw_vec,
               rf,
               corr_prem_res,
               df_lobs_prem_risk)
  prem = Array{Float64}(undef, 2)
  name = lob[1, :name]
  ## calculate written net premium and earned net premium
  re_prop_q = [lob[1, :re_prop_q_py],
               lob[1, :re_prop_q_cy],
               lob[1, :re_prop_q_ny]]
  upr = [lob[1, :upr_py], lob[1, :upr_cy], lob[1, :upr_ny]]
  ## upr_gross[PY] not defined, set == Inf:
  upr_gross =    upr ./ (1 .- [1, re_prop_q[PY], re_prop_q[CY]])
  prem_gross_w =
    [lob[1, :prem_gross_w_py], lob[1, :prem_gross_w_cy]]
  prem_w = (1 .- [re_prop_q[PY], re_prop_q[CY]]) .* prem_gross_w
  prem_gross_cy =
    prem_gross_w[CY] + upr_gross[CY] - upr_gross[NY]
  for 𝑡 ∈ [PY, CY]
    prem[𝑡] = prem_w[𝑡] + upr[𝑡] - upr[𝑡 + 1]
  end
  ## calculate statistical parameters
  vol_prem = max(prem[PY], prem[CY])
  np_fac =
    df_lobs_prem_risk[df_lobs_prem_risk[:abbrev] .== name,
                      :re_np_prem][1,1]
  vol_prem_vc =
    df_lobs_prem_risk[df_lobs_prem_risk[:abbrev] .== name,
                      :prem_gross_vc][1,1]
  vol_prem_sd = vol_prem * vol_prem_vc * np_fac
  β =  β_raw_vec / sum(β_raw_vec)
  vol_res =
    lob[1, :res_undisc_py] * (β ⋅ cumprod(1 ./ (1 .+ rf)))
  vol_res_vc =
    df_lobs_prem_risk[df_lobs_prem_risk[:abbrev] .== name,
                      :res_net_vc][1,1]
  vol_res_sd = vol_res * vol_res_vc
  vol_prem_res_sd =
    sqrt(([vol_prem_sd, vol_res_sd]' *
          corr_prem_res *
            [vol_prem_sd, vol_res_sd])[1,1])
  return NLLob(name,
               lob[1, :index],
               prem_gross_w, prem_w,
               prem_gross_cy, prem,
               upr_gross, upr,
               re_prop_q, β,
               vol_prem,  vol_prem_vc,
               vol_res,
               vol_prem_res_sd)
end

"""
`premrestotalsd(nllobs::Vector{NLLob}, corr_lob::Matrix{Float64})`

Calculates the standard deviation of the total premium reserve
"""
function premrestotalsd(nllobs::Vector{NLLob},
                        corr_lob::Matrix{Float64})
  indices = Array{Int}(undef, 0)
  prem_res_sd = Array{Float64}(undef, 0)
  for 𝑖 ∈ 1:length(nllobs)
    push!(indices, nllobs[𝑖].index)
    push!(prem_res_sd, nllobs[𝑖].vol_prem_res_sd)
  end
  prem_res_total_sd =
    sqrt(prem_res_sd' * corr_lob[indices, indices] * prem_res_sd)
  return prem_res_total_sd
end
