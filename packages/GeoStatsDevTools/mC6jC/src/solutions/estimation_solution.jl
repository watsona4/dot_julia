# ------------------------------------------------------------------
# Licensed under the ISC License. See LICENCE in the project root.
# ------------------------------------------------------------------

function Base.getindex(solution::EstimationSolution{<:RegularGrid}, var::Symbol)
  sz = size(solution.domain)
  M = reshape(solution.mean[var], sz)
  V = reshape(solution.variance[var], sz)
  (mean=M, variance=V)
end
