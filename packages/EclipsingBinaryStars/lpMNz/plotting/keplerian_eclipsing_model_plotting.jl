#=
    true_anom_plotting
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

using PyPlot
using PyCall
@pyimport matplotlib.patches as patches
using LaTeXStrings

include("true_anom.jl")

function plot_binary_ν( s :: Binary
                      , νs
                      ; xpad    = 0.1
                      , ypad    = 0.1
                      , lw      = 0.1
                      , nlimbs  = 100
                      , fc_rgb1 = [0,0,1]
                      , fc_rgb2 = [1,0,0]
                      , trace   = false
                      , title   = ""
                      )

    x,y,z = zeros(νs),zeros(νs),zeros(νs)
    for (i,ν) in enumerate(νs)
        x[i],y[i],z[i] = get_sky_pos(s.orb, ν)
    end

    xbot = min(-s.pri.r, minimum(x) - s.sec.r)
    xtop = max(+s.pri.r, maximum(x) + s.sec.r)
    ybot = min(-s.pri.r, minimum(y) - s.sec.r)
    ytop = max(+s.pri.r, maximum(y) + s.sec.r)

    xran = xtop - xbot
    yran = ytop - ybot

    ax = gca()
    ax[:set_xlim](xbot - xpad*xran, xtop + xpad*xran)
    ax[:set_ylim](ybot - ypad*yran, ytop + ypad*yran)

    radiusfrac = linspace(1.0, 1.0/nlimbs, nlimbs)
    colorscale = linspace(0.3, 1.0, nlimbs)

    trace_zshift = 2*max(maximum(z), abs(minimum(z)))
    for j in 1:nlimbs-1
        rf = radiusfrac[j]
        cs = colorscale[j]
        if j == 1
            linewidth = lw
        else
            linewidth = 0
        end

        ax[:add_artist]( patches.Circle( [0.0,0.0]
                                       , s.pri.r*rf
                                       , fc        = fc_rgb1*cs
                                       , ec        = "black"
                                       , linewidth = linewidth
                                       , zorder    = 0.0
                                       )
                       )
        for i in 1:length(νs)
            ax[:add_artist]( patches.Circle( [ x[i]
                                             , y[i]
                                             ]
                                           , s.sec.r*rf
                                           , fc        = fc_rgb2*cs
                                           , ec        = "black"
                                           , linewidth = linewidth
                                           , zorder    = z[i]
                                           )
                           )
            if trace & (j == 1)
                ax[:add_artist]( patches.Circle( [ x[i]
                                                 , y[i]
                                                 ]
                                               , s.sec.r*rf
                                               , fc        = [0,0,0,0]
                                               , ec        = "green"
                                               , linewidth = 0.5
                                               , zorder    = z[i] + trace_zshift
                                               )
                               )
            end
        end
    end

    ax[:set_aspect]("equal")
    ax[:set_title](title)

end

function plot_lightcurve( s :: Binary
                        ; title  = ""
                        , xlabel = "phase"
                        , ylabel = "visible fraction"
                        )
    # number of points per eclipse
    semi_npnts_e = 100      # half number of points to use per eclipse

    νs_e,emorphs = get_eclip_morphs(s)
    num_eclips = sum(emorphs .> 0)
    if num_eclips == 0
        println("no eclipses to plot")
        return
    end

    νs = Array{Float64,1}(2*num_eclips*semi_npnts_e)    

    νs_e,emorphs = get_eclip_morphs(s)
    j = 1
    k = semi_npnts_e
    for (i,emorph) in enumerate(emorphs)
        if emorph > 0
            outer_crit_νs = get_outer_critical_νs(s,νs_e[i])
            if emorph == 2
                inner_crit_νs = get_inner_critical_νs(s,νs_e[i])
            else
                inner_crit_νs = (νs_e[i],νs_e[i])
            end

            νs[j:k] = linspace(outer_crit_νs[1],inner_crit_νs[1], semi_npnts_e)
            j += semi_npnts_e
            k += semi_npnts_e

            νs[j:k] = linspace(outer_crit_νs[2],inner_crit_νs[2], semi_npnts_e)
            j += semi_npnts_e
            k += semi_npnts_e
        end
    end

    f1 = Array{Float64,1}(length(νs))
    f2 = Array{Float64,1}(length(νs))

    times = zeros(νs)
    for (i,ν) in enumerate(νs)
        f1[i],f2[i] = get_visible_frac(s,ν)
        M = mod2pi(get_M_from_ν(s.orb,ν))   # just to keep things positive =)
        times[i] = (M*s.per)/(2π)
    end
    
    ftot = f1 + f2

    inds  = sortperm(times)
    times = times[inds]
    ftot  = ftot[inds]

    times -= times[indmin(ftot)]

    phase = times/s.per
    inds = phase .< -0.5
    phase[inds] += 1.0

    inds  = sortperm(phase)
    phase = phase[inds]
    ftot  = ftot[inds]

    fmax  = maximum(ftot)

    color = "blue"
    plot( [-0.5, phase..., 0.5]
        , [fmax, ftot... , fmax]
        , linewidth = 1
        , color = color
        )

    plot( phase
        , ftot
        , marker = "o"
        , markersize = 3
        , linestyle = "none"
        , color = color
        )

    ax = gca()
    ax[:set_title](title)
    ax[:set_xlabel](xlabel)
    ax[:set_ylabel](ylabel)
end

function test_binary()
    #ω = 0.0
    ω = pi/3
    title = L"$\omega=\pi/3$"
    #ε = 0.0
    ε = 0.5
    title = latexstring(title, L", $\varepsilon=0.5$")
    #i=0.0
    i=deg2rad(87)
    title = latexstring(title, L", $i=87\degree$")
    a=20.0
    title = latexstring(title, L", $a=20$R$_\odot$")

    pri = Star(m=5, r=2)
    title = latexstring(title, L", $r_1=2$R$_\odot$")
    sec = Star(m=1, r=1)
    title = latexstring(title, L", $r_2=1$R$_\odot$")

    orb = Orbit(ω=ω, ε=ε, i=i, a=a)
    s = Binary(pri=pri, sec=sec, orb=orb)

    per = @sprintf("%.2fdy", s.per)
    title = latexstring(title, ", \$P\$=$per")
    return s, title
end

function test_lightcurve()
    s,title = test_binary()
    plot_lightcurve(s, title=title)
    show()
end
test_lightcurve()

function test_plot_binary()
    s,title = test_binary()
    νs = linspace(0,2pi, 50)
    plot_binary_ν(s, νs, title=title)
    show()
end
#test_plot_binary()

function test_plot_binary_crit_νs()
    s,title = test_binary()
    ν_e, emorphs = get_eclip_morphs(s)

    crit_νs  = Array{Float64,1}(0)

    for (i,emorph) in enumerate(emorphs)
        if emorph > 0
            append!(crit_νs, ν_e[i])
            append!(crit_νs, get_outer_critical_νs(s,ν_e[i]))
        end
        if emorph == 2
            append!(crit_νs, get_inner_critical_νs(s,ν_e[i]))
        end
    end
    plot_binary_ν(s, crit_νs, trace=true, title=title)
    show()
end
#test_plot_binary_crit_νs()



#ω = pi/3
#orb = Orbit(ω=ω, ε=0.5, i=deg2rad(87), a=20.0)
#pri = Star(m=5, r=2)
#sec = Star(m=1, r=1)
#s = Binary(pri=pri, sec=sec, orb=orb)
#estatus = get_eclip_morphs(s)
## for this system π/2 - ω is at annular eclipser
#ν_e = π/2 - ω
#crit_νs = get_outer_critical_νs(s, ν_e)
#
#t = get_time_btw_νs(s, crit_νs[1], crit_νs[2])
#println(t, " in days")
##crit_νs = get_inner_critical_νs(s, ν_e)
##crit_νs = timer_func(s, ν_e)
## for this system 3π/2 - ω is a partial eclipser
##icrit_νs = get_outer_critical_νs(s,3π/2 - ω)
#νs = [crit_νs[1], crit_νs[2]]
##νs = linspace(crit_νs[1], crit_νs[2], 5)
#plot_binary_ν(s, νs)
#show()
