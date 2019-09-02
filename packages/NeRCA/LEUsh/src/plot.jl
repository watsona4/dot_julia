# Creates `PGFPlotsX.Coordinates` from hits
function ZTCoordinates(hits::Vector{CalibratedHit}; offset=0)
    PGFPlotsX.Coordinates(map(h->h.t - offset, hits), map(h->h.pos.z, hits))
end

"""
    function ztplot(hits::Vector{CalibratedHit}; du=nothing, t₀=0) -> PGFPlotsX.Axis

Create a zt-plot from a set of hits using PGFPlotsX. If no `du` is provided,
the brightest DU will be determined.
"""
function ztplot(hits::Vector{CalibratedHit}; du=nothing, t₀=0)
    if du == nothing
        du = NeRCA.most_frequent(h -> h.du, hits)
        hits = filter(h -> h.du == du, hits)
    end
    sort!(hits, by=h->h.t)
    triggered_hits = filter(h -> h.triggered, hits)
    ax = @pgf Axis({xlabel=raw"time [\si{\ns}]", ylabel=raw"z [\si{\m}]"})
    push!(ax,  @pgf PlotInc({only_marks, mark="*", mark_size=".8"}, ZTCoordinates(hits, offset=t₀)))
    push!(ax, LegendEntry("hits"))
    push!(ax,  @pgf PlotInc({only_marks, mark="x", mark_size="4"}, ZTCoordinates(triggered_hits, offset=t₀)))
    push!(ax, LegendEntry("triggered"))
    ax
end


"""
    function ztplot(hits::Vector{CalibratedHit}, fit::NeRCA.ROyFit; t₀=0) -> PGFPlotsX.Axis

Create a zt-plot from hits and a ROyFit using PGFPlotsX.
"""
function ztplot(hits::Vector{CalibratedHit}, fit::NeRCA.ROyFit; t₀=0)
    ax = ztplot(hits; t₀=t₀)
    zs = range(0, 800, length=200)
    dᵧ, ccalc = NeRCA.make_cherenkov_calculator(fit.sdp)
    push!(ax, @pgf PlotInc({thick}, Coordinates(ccalc.(zs) .- t₀, zs)))
    push!(ax, LegendEntry("fit"))
    ax
end


"""
    f(dom_positions, track::NeRCA.Track)

Plot recipe for z-t-plots.
"""
@recipe function f(dom_positions, track::NeRCA.Track)
    # layout := @layout [a b]
    layout := (2, 2)

    seriestype := :scatter

    xlabel := "time [ns]"
    ylabel := "z [m]"

    @series begin
        subplot := 1
        ccalc = NeRCA.make_cherenkov_calculator(track)
        ccalc.(dom_positions), [p.z for p in dom_positions]
    end

    xlabel := "x [m]"
    ylabel := "y [m]"

    @series begin
        subplot := 2
        label := "DOMs"
        [p.x for p in dom_positions], [p.y for p in dom_positions]
        [track.pos.x], [track.pos.y]
    end

    @series begin
        subplot := 2
        label := "Track"
        [track.pos.x], [track.pos.y]
    end

    @series begin
        subplot := 3
    end
end


"""
    f(hits::Vector{CalibratedHit}; label="hits", highlight_triggered=false, multiplicities=false, Δt=20, du=0, t₀=0)

Plot recipe to plot simple z-t-plots.
"""
@recipe function f(hits::Vector{CalibratedHit}; label="hits", markersize=4, highlight_triggered=false, multiplicities=false, Δt=20, du=0, t₀=0)
    seriestype := :scatter

    xlabel := "time [ns]"
    ylabel := "z [m]"
    markerstrokewidth := 0

    if du > 0
        hits = filter(h -> h.du == du, hits)
    end

    thits = filter(h -> h.triggered, hits)

    @series begin
        label := label
        if multiplicities
            markersize := count_multiplicities(hits)[1]
            markeralpha := 0.8
        end
        [h.t - t₀ for h in hits], [h.pos.z for h in hits]
    end

    if highlight_triggered
        @series begin
            label := "triggered"
            markersize := 1
            marker := :x
            markerstrokewidth := 1
            [h.t - t₀ for h in thits], [h.pos.z for h in thits]
        end
    end
end


@recipe function f(hits::Vector{CalibratedHit}, track::Track; max_z=nothing)
    seriestype := :scatter

    xlabel := "time [ns]"
    ylabel := "z [m]"
    background_color_legend := PlotThemes.RGBA{Float64}(1.0,1.0,1.0,0.4)
    markerstrokewidth := 0

    thits = filter(h -> h.triggered, hits)
    if max_z == nothing
        max_z = maximum(map(h->h.pos.z, hits))
    end

    dus = sort(unique(map(h->h.du, thits)))
    ccalc = make_cherenkov_calculator(track, v=norm(track.dir)*1e9)

    colours = palette(:default)
    for (idx, du) in enumerate(dus)
        du_hits = filter(h -> h.du == du, hits)
        @series begin
            label := "DU $(du)"
            linewidth := 3
            markersize := 5
            markercolor := colours[idx]
            du_hits
        end
        x = du_hits[1].pos.x
        y = du_hits[1].pos.y
        zs = range(0, max_z, length=200)
        @series begin
            linewidth := 10
            label := ""
            markersize := 1
            markercolor := colours[idx]
            [ccalc(Position(x, y, z)) for z in zs], zs
        end
    end
end


@recipe function f(hits::Vector{CalibratedHit}, fit::ROyFit; label="", max_z=nothing)
    seriestype := :scatter

    xlabel := "time [ns]"
    ylabel := "z [m]"
    background_color_legend := PlotThemes.RGBA{Float64}(1.0,1.0,1.0,0.4)
    markerstrokewidth := 0

    triggered_hits = filter(h -> h.triggered, hits)
    if max_z == nothing
        max_z = maximum(map(h->h.pos.z, hits))
    end

    dᵧ, ccalc = make_cherenkov_calculator(fit.sdp)

    @series begin
        markersize := 2
        marker := :circle
        markeralpha := 0.7
        label := label
        hits
    end
    @series begin
        markersize := 5
        markeralpha := 0.4
        fillcolor := nothing
        marker := :circle
        label := ""
        triggered_hits
    end
    @series begin
        markersize := 10
        marker := :cross
        label := ""
        fit.selected_hits
    end
    zs = range(0, max_z, length=200)
    @series begin
        linewidth := 10
        label := ""
        markersize := 1
        label := ""
        ccalc.(zs), zs
    end
end
