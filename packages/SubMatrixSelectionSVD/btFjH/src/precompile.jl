# function _precompile_()
#     ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
#     precompile(Tuple{typeof(SubMatrixSelectionSVD.α), Base.UnitRange{Int64}, Base.LinAlg.Symmetric{Float64, Array{Float64, 2}}})
#     precompile(Tuple{getfield(SubMatrixSelectionSVD, Symbol("##projectionscorefiltered#10")), Int64, Array{Float64, 1}, typeof(identity), Array{Float64, 2}, Base.UnitRange{Int64}, Array{Float64, 1}})
#     # precompile(Tuple{getfield(SubMatrixSelectionSVD, Symbol("##smssvd#19")), Int64, Int64, typeof(identity), Array{Float64, 2}, Int64, Array{Float64, 1}})
#     precompile(Tuple{getfield(SubMatrixSelectionSVD, Symbol("#kw##projectionscorefiltered")), Array{Any, 1}, typeof(SubMatrixSelectionSVD.projectionscorefiltered), Array{Float64, 2}, Base.UnitRange{Int64}, Array{Float64, 1}})
#     precompile(Tuple{typeof(SubMatrixSelectionSVD._αfiltered), Array{Float64, 2}, Base.UnitRange{Int64}, Array{Float64, 1}, Array{Float64, 1}})
#     precompile(Tuple{typeof(SubMatrixSelectionSVD.smssvd), Array{Float64, 2}, Int64, Array{Float64, 1}})
#     precompile(Tuple{typeof(SubMatrixSelectionSVD.smssvd), Array{Float64, 2}, Int64})
#     precompile(Tuple{typeof(SubMatrixSelectionSVD.smssvd), Array{Float64, 2}, Array{Int64, 1}})
# end
