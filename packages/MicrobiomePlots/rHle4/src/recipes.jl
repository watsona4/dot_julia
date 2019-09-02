@recipe function f(pc::PCoA)
    xticks := false
    yticks := false
    xlabel --> "PCo1 ($(round(variance(pc, 1) * 100, digits = 2))%)"
    ylabel --> "PCo2 ($(round(variance(pc, 2) * 100, digits = 2))%)"
    seriestype := :scatter
    principalcoord(pc, 1), principalcoord(pc,2)
end

@userplot AbundancePlot
@recipe function f(plt::AbundancePlot; topabund=10, sort::Vector{Int}=collect(1:nsites(plt.args[1])))
    abun = plt.args[1]
    typeof(abun) <: AbstractComMatrix || error("AbundancePlot not defined for $(typeof(abun))")

    topabund = min(topabund, nfeatures(abun))
    2 <= topabund < 12 || error("n must be between 2 and 12")

    top = filterabund(abun, topabund)

    rows = featurenames(top)

    yflip := true
    bar_position := :stack
    label := rows
    GroupedBar((1:nsamples(top), Matrix(occurrences(top)[:,sort]')))
end

struct AnnotationBar
    labels::Array{<:AbstractString,1}
    colors::Array{<:Color,1}
end

annotationbar(labels::Array{<:AbstractString,1}, colors::Array{<:Color,1}) = AnnotationBar(labels, colors)
annotationbar(colors::Array{<:Color,1}) = AnnotationBar(["sample$i" for i in 1:length(colors)], colors)

@recipe function f(bar::AnnotationBar)
    xs = Int[]
    for i in 1:length(bar.colors)
        append!(xs, [0,0,1,1,0] .+ (i-1))
    end
    xs = reshape(xs, 5, length(bar.colors))
    ys = hcat([[0,1,1,0,0] for _ in bar.colors]...)

    fc = reshape(bar.colors, 1, length(bar.colors))


    seriestype := :path
    fill := (0,1)
    fillcolor := fc
    legend := false
    color --> :black
    ticks := false
    framestyle := false
    xaxis --> false
    yaxis --> false
    xs, ys
end


# From Michael K. Borregaard (posted to slack 2018-05-18)
# Usage:
#
# x = randn(100)
# y = randn(100) + 2
# y[y.<0] = 0
#
# zeroyplot(x,y, yscale = :log10, color = :red, markersize = 8)
# @userplot ZeroYPlot
# @recipe function f(h::ZeroYPlot)
#            length(h.args) != 2 && error("zeroyplot only defined for x and y input arguments")
#            x, y = h.args
#            val0 = y .== 0
#
#            layout := @layout([a
#                               b{0.05h}])
#
#            markeralpha --> 0.4
#            seriestype --> :scatter
#
#            @series begin
#                primary := false
#                subplot := 2
#                yscale := :identity
#                ylim := (-1,1)
#                yticks := ([0],[0])
#                grid := false
#                x[val0], y[val0]
#            end
#
#            subplot := 1
#            x[.!val0], y[.!val0]
# end
