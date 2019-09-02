# This file is part of Kpax3. License is MIT.

function loss_binder(R::Vector{Int},
                     P::Matrix{Float64})
  n = length(R)

  loss = 0.0
  for j in 1:(n - 1), i in (j + 1):n
    loss += (R[i] == R[j]) ? 1 - P[i, j] : P[i, j]
  end

  loss
end
