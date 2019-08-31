# ------------------------------------------------------------------
# Licensed under the ISC License. See LICENCE in the project root.
# ------------------------------------------------------------------

function Base.getindex(solution::SimulationSolution{<:RegularGrid}, var::Symbol)
  sz = size(solution.domain)
  [reshape(real, sz) for real in solution.realizations[var]]
end
