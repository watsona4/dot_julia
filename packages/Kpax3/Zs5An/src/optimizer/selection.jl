# This file is part of Kpax3. License is MIT.

function selection(fitness::Array{Float64})
  (a1, a2, b1, b2) = StatsBase.sample(1:length(fitness), 4, replace=false)

  i1 = fitness[a1] > fitness[a2] ? a1 : a2
  i2 = fitness[b1] > fitness[b2] ? b1 : b2

  (i1, i2)
end
