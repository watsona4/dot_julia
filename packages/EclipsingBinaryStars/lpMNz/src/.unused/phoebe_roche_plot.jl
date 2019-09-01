#=
    phoebe_roche_plot
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

using PyPlot
include("roche.jl")

q = 0.5
δ = 1.0
F = 1.0


xL1 = get_lagrangian_pnt(1,q)
println("xL1: ", xL1)
pL1 = get_Ω_L1(q,δ,F)
println("pL1: ", pL1)

plotcolors = ["blue", "green", "black", "magenta", "red"]
pots = [6.0, 3.5, 2.87584, 2.8, 2.7]
#plotcolors = ["blue", "green", "black", "magenta"]
#pots = [6.0, 3.5, 2.87584, 2.8]
#plotcolors = ["blue", "green", "black"]
#pots = [6.0, 3.5, 2.87584]
n = 1000

θs = linspace(0, 2π, n+1)[1:end-1]
λs = cos.(θs)
μs = zeros(n)
νs = sin.(θs)

for (plotcolor,pot) in zip(plotcolors,pots)
    ϱs = get_ϱ1(pot, q, δ, λs, νs, F)
    xs,ys,zs = rλμν_to_xyz(ϱs,λs,μs,νs)

    plot( xs
        , zs
        , marker    = "o"
        , markersize = 1.0
        , linestyle = "None"
        , color     = plotcolor
        )

    ϱs = get_ϱ2(pot, q, δ, λs, νs, F)
    xs,ys,zs = rλμν_to_xyz(ϱs,λs,μs,νs)
    xs = 1 - xs

    plot( xs
        , zs
        , marker    = "o"
        , markersize = 1.0
        , linestyle = "None"
        , color     = plotcolor
        )


end
show()
