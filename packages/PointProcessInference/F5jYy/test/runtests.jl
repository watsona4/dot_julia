using Test
using PointProcessInference
using Statistics
using Random
Random.seed!(1234)

observations, parameters, λinfo = PointProcessInference.loadexample("generated")
res = PointProcessInference.inference(observations; parameters...)

observations = res.observations
breaks = res.breaks
title = res.title
ψ = res.ψ
N = res.N
acc = res.acc
λ = λinfo.λ
T = res.T
coeff = (λ.(breaks[1:end-1]) + λ.(breaks[2:end]))/2
coeffhat = vec(mean(ψ, dims=1))
margstd = vec(std(ψ, dims=1))
@test maximum(abs.(coeffhat - coeff)./margstd) < 2.6
#include(joinpath(dirname(pathof(PointProcessInference)), "..", "contrib", "process-output-simple.jl")
