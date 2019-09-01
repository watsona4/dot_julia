#=
    logP_eccn_test
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#
using PyPlot

#using EclipsingBinaryStars
include("../src/EclipsingBinaryStars.jl")

fake_pri = EclipsingBinaryStars.getStar(m=1, r=1)
fake_sec = EclipsingBinaryStars.getStar(m=1, r=1)

ω  = 0.0
i  = 90.0
εs = 0:0.05:1-eps()
logps = linspace(0.2,3,20)
Ps = 10.0.^logps

xs = Array{Float64,1}(length(Ps)*length(εs))
ys = Array{Float64,1}(length(Ps)*length(εs))
mask = Array{Bool,1}(length(Ps)*length(εs))

ind = 1
for P in Ps
    for ε in εs
        eb = EclipsingBinaryStars.getBinary(fake_pri, fake_sec, ω=ω, i=i, ε=ε, P=P)
        mask[ind] = EclipsingBinaryStars.detached_check(eb)
        xs[ind] = P
        ys[ind] = ε
        ind += 1
        #println("ε = ", ε)
        #println(isdetached)
    end
end

plot( xs[mask]
    , ys[mask]
    , color  = "blue"
    , marker = "o"
    , linewidth = 0
    )
plot( xs[.!mask]
    , ys[.!mask]
    , color  = "red"
    , marker = "o"
    , linewidth = 0
    )

ax = gca()
ax[:set_xscale]("log")
show()
