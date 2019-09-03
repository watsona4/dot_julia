using BenchmarkTools
include("parallelGeneration.jl")

setRNGs(1)
nt = Threads.nthreads()
out = Vector{Float64}(undef, nt)

N0 = 2^25
@btime foo!($out, $N0)
