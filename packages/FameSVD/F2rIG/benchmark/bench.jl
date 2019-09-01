include("../src/FameSVD.jl")

using BenchmarkTools
using LinearAlgebra
using Statistics
using Plots

function benchmark_pd()
  t = Array{Float64, 2}(undef, 10, 2)
  n = 1000

  FameSVD.fsvd(rand(Float64, 4, 2))
  FameSVD.svd(rand(Float64, 4, 2))

  for i = 1:10
    a = @benchmark FameSVD.fsvd(A) setup=(A=randn(Float64, $i * $n, $n))
    b = @benchmark svd(A) setup=(A=randn(Float64, $i * $n, $n))

    t[i, 1] = median(a).time
    t[i, 2] = median(b).time
  end

  png(plot(1:10, t, xaxis="Matrix rows size(x * 1000)", yaxis="execution time", labels=["fsvd", "svd"]), "bench.png")
end
