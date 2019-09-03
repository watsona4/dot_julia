using RNGPool
using Random

function foo!(out::Vector{Float64}, N::Int64)
  nt = Threads.nthreads()
  M::Int64 = div(N, nt)
  Threads.@threads for i in 1:nt
    rng::RNG = getRNG()
    v::Float64 = 0.0
    for j in 1:M
      v += rand(rng)
    end
    out[i] = v / M
  end
end
