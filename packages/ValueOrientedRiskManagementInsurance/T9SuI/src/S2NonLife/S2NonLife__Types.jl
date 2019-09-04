export NLLob, PY, CY, NY

const PY, CY, NY = 1, 2, 3   ## previous, current, next year

"Line of Business (Non-Life)"
mutable struct NLLob
  "`AbstractString`: Name of the line of business"
  name::Symbol
  "`Int`: Identifying index of the line of business"
  index::Int
  "`Vector{Float64}`: Written gross premium"
  prem_gross_w::Vector{Float64}
  "`Vector{Float64}`: Written premium"
  prem_w::Vector{Float64}
  "`Float64`: Gross premium earned"
  prem_gross_cy::Float64
  "`Vector{Float64}`: Premium earned"
  prem::Vector{Float64}
  "`Vector{Float64}`: Unearned gross prem. reserve"
  upr_gross::Vector{Float64}
  "`Vector{Float64}`: Unearned premium reserve"
  upr::Vector{Float64}
  "`Vector{Float64}`: Prop. reinsurence ceded"
  re_prop_q::Vector{Float64}
  "`Vector{Float64}`: Reserve pattern"
  β::Vector{Float64}
  "`Float64`:  Volume factor premium"
  vol_prem::Float64
  "`Float64`: Var. coeff. net prem risk"
  vol_prem_vc::Float64
  "`Float64`: Volume factor reserve"
  vol_res::Float64
  "`Float64`: Standard deviation prem+res"
  vol_prem_res_sd::Float64
end
