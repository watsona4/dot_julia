include("parallelGeneration.jl")

import Statistics.mean

setRNGs(1)
nt = Threads.nthreads()
out = Vector{Float64}(undef, nt)

N0 = 2^25
foo!(out, N0)
@test mean(out) ≈ 0.5 atol=0.001
