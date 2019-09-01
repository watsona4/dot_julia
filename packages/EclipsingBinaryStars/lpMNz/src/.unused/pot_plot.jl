#=
    phoebe_roche_plot
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

using PyPlot
include("roche.jl")
include("lagrangian_points.jl")

#q = 0.5
#δ = 1.0
q = 0.0009543   # jupiter/sun mass ratio
r1 = 1.0        # radius of the sun
r2 = 0.10049    # jupiter radius in Rsol
#δ = 1119.0    # jupiter sun distance in Rsol
δ = 215.0    # jupiter sun distance in Rsol
F = 1.0

nx = 200     # should be even
nz = 100

xL1 = get_lagrangian_pnt(1,q,δ)
xL2 = get_lagrangian_pnt(2,q,δ)
xL3 = -get_lagrangian_pnt(3,q,δ)
println("xL1: ", xL1)

xL4 = δ*cosd(60)
yL4 = δ*sind(60)

xs = linspace(xL3, xL2, nx)
#zs = linspace(0.0, yL4, nz)
zs = linspace(0.0, 1.0, nz)

pots = Array{Float64,2}(nz,nx)

for (i,x) in enumerate(xs), (j,z) in enumerate(zs)
    λ,μ,ν = xyz_to_λμν(x,0.0,z)
    ϱ = sqrt(x^2 + z^2)

    pots[j,i] = get_Ω(ϱ, q, δ, λ, ν, F)

end

plotpot = Array{Float64,2}(2*nz - 1, nx)
for i in 1:nx
    plotpot[:,i] = vcat(pots[end:-1:2,i], pots[:,i])
end
zs = vcat( -zs[end:-1:2]
         , zs
         )

plotpot = log10.(plotpot)

pcolormesh(xs, zs, plotpot)
colorbar()


plot(xL1, 0.0, marker = "o", color = "red")
plot(xL2, 0.0, marker = "o", color = "red")
plot(xL3, 0.0, marker = "o", color = "red")
#plot(xL4, yL4, marker = "o", color = "red")
#plot(xL4, -yL4, marker = "o", color = "red")

#ax = gca()
#ax[:set_aspect]("equal")



pL1 = get_Ω(xL1, q, δ, 1, 0, F)
println("pL1: ", pL1)

pr1 = get_Ω(r1, q, δ, 1, 0, F)
println("pr1: ", pr1)

println("")
ppL1 = get_Ω_prime(pL1, q)
println("ppL1: ", ppL1)
temp = δ - r2
pr2 = get_Ω(temp, q, δ, 1, 0, F)
println("pr2: ", pr2)
ppr2 = get_Ω_prime(pr2, q)
println("ppr2: ", ppr2)

println("pr1/pL1: ", pr1/pL1)
println("pr2/pL1: ", pr2/pL1)
println("ppr2/ppL1: ", pr2/pL1)

show()


##plotpot = log10.(log10.(plotpot))
##plotpot = log10.(plotpot)
#
#masknan = .!(isnan.(plotpot))
#maskinf = .!(isinf.(plotpot))
#
#mask = masknan .* maskinf
#println(maximum(plotpot[mask]))
#println(minimum(plotpot[mask]))
##pcolormesh(xs, zs, plotpot)
#contour(xs, zs, plotpot)



#plotcolors = ["blue", "green", "black", "magenta", "red"]
#
#xL1 = get_lagrangian_pnt(1,q)
#println("xL1: ", xL1)
#potL1 = get_Ω_Lpnt(1,q,δ,F)
#println("potL1: ", potL1)
#
#xL2 = get_lagrangian_pnt(2,q)
#println("xL2: ", xL2)
#potL2 = get_Ω_Lpnt(2,q,δ,F)
#println("potL2: ", potL2)
#
#xL3 = get_lagrangian_pnt(3,q)
#println("xL3: ", xL3)
#potL3 = get_Ω_Lpnt(3,q,δ,F)
#println("potL3: ", potL3)
#
##pots = [ 6.0 , 3.5 , 2.87584, 2.8, 2.7]
#
#pots = [3*potL1, 2*potL1, potL1, potL3, 0.5*(potL2 + potL3)]
##plotcolors = ["blue", "green", "black", "magenta"]
##pots = [6.0, 3.5, 2.87584, 2.8]
##plotcolors = ["blue", "green", "black"]
##pots = [6.0, 3.5, 2.87584]
#n = 1000
#
#θs = linspace(0, 2π, n+1)[1:end-1]
#λs = cos.(θs)
#μs = zeros(n)
#νs = sin.(θs)
#
#xmin = 1.0
#xmax = 0.0
#for (plotcolor,pot) in zip(plotcolors,pots)
#    #ϱs = get_ϱ1(pot, q, δ, λs, νs, F)
#    #xs,ys,zs = rλμν_to_xyz(ϱs,λs,μs,νs)
#    #mask = .!isnan.(xs)
#    #xmin = min(xmin, minimum(xs[mask]))
#    #xmax = max(xmax, maximum(xs[mask]))
#
#    #plot( xs
#    #    , zs
#    #    , marker    = "o"
#    #    , markersize = 1.0
#    #    , linestyle = "None"
#    #    , color     = plotcolor
#    #    )
#
#    ϱs = get_ϱ2(pot, q, δ, λs, νs, F)
#    xs,ys,zs = rλμν_to_xyz(ϱs,λs,μs,νs)
#    xs = δ - xs
#    mask = .!isnan.(xs)
#    if sum(mask) > 0
#        xmin = min(xmin, minimum(xs[mask]))
#        xmax = max(xmax, maximum(xs[mask]))
#
#        plot( xs
#            , zs
#            , marker    = "o"
#            , markersize = 1.0
#            , linestyle = "None"
#            , color     = plotcolor
#            )
#    end
#
#end
#
#ax = gca()
#
#xran = xmax - xmin
#println("xmin: ", xmin)
#println("xmax: ", xmax)
#println("xran: ", xran)
#pad = 0.001
#ax[:axvspan]( xL1 - pad*xran
#            , xL1 + pad*xran
#            , color = "black"
#            )
#
#ax[:set_aspect]("equal")
#
#
#show()
