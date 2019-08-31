__precompile__()

module CornerPlot

using DataFrames
using Gadfly
using Compose
using Viridis
using Measures

export corner


function corner(samples::Union{Array{Float64}, AbstractDataFrame};
                bins::Union{Int, Array{Int, 1}, Array{Array{Float64, 1}, 1}} = 20,
                hexbins::Union{Int, Array{Int, 1}} = 50,
                range::Union{Array{Tuple{Float64,Float64}, 1}, Void} = nothing,
                varnames::Union{Array{String, 1}, Array{Symbol, 1}, Void} = nothing,
                truthvals::Union{Array{Float64, 1}, Array{Array{Float64, 1}}, Void} = nothing,
                plotsize::Measures.Length{:mm,Float64} = 20cm)

    # If samples are in dataframe, get array of values
    if typeof(samples) <: AbstractDataFrame

        # only take relevant columns if given
        if typeof(varnames) == Array{Symbol, 1}
            samples = Array(samples[:, varnames])
        end

    # in case a 1-d array is passed
    elseif length(size(samples)) == 1
        samples = reshape(samples, (size(samples)[1], 1))
    end

    nsamps = size(samples)[1]
    ndims = size(samples)[2]

    if ndims > nsamps
        throw(ArgumentError("samples array should not have more dimensions than samples, try reshaping/transposing"))
    end

    # now to deal with bins
    if typeof(bins) == Int
        nbins = [bins for a in 1:ndims]

        if range != nothing
            bins = [linspace(r..., nbins[i]) for (i, r) in enumerate(range)]
        else
#            bins = nothing
            bins = [[minimum(samples[:, i]), maximum(samples[:, i])] for i in 1:ndims]
        end

    elseif typeof(bins) == Array{Int, 1}
        nbins = bins

        if range != nothing
            bins = [linspace(r..., nbins[i]) for (i, r) in enumerate(range)]
        else
#            bins = nothing
            bins = [[minimum(samples[:, i]), maximum(samples[:, i])] for i in 1:ndims]
        end

    else
        nbins = [length(a) - 1 for a in bins]
    end

    # and hexbins
    if typeof(hexbins) == Int
        hexbins = [hexbins for a in 1:ndims]
    end

    # set up the plots
    set_default_plot_size(plotsize, plotsize)
    subplots = Array{Context}(ndims, ndims)

    for i in 1:ndims

        # make an array for the layers of the plots
        diagarr = []

        # make a vertical line layer if requested
        if truthvals != nothing

            # turn a single array into an array of arrays
            if typeof(truthvals) == Array{Float64, 1}
                truthvals = [[val] for val in truthvals]
            end

            vline = layer(xintercept = truthvals[i], Geom.vline,
                          Theme(default_color = colorant"red"))
            append!(diagarr, vline)
        end

        # grab only those samples which will be in the plot range
        if bins != nothing
            histsamps = samples[:, i][bins[i][1] .<= samples[:, i] .< bins[i][end]]
        else
            histsamps = samples[:, i]
        end

        # this is the 1-d histogram layer
        append!(diagarr, layer(x = histsamps, Geom.histogram(bincount = nbins[i]),
                               Theme(default_color = Viridis.viridis(0.5))))

        # for last diagonal, add axis label if given
        xlabel = nothing
        ylabel = nothing
        if varnames != nothing
            if i == 1
                ylabel = String(varnames[i])
            elseif i == ndims
                xlabel = String(varnames[i])
            end
        end

        # and plot the diagonal histogram
        subplots[i, i] = render(plot(diagarr...,
                                     Guide.xlabel(nothing), Guide.ylabel(nothing),))

        # now loop over the subplots down the column
        for j in (i + 1):ndims

            # make layer array for each offdiagonal plot
            offdiag = []

            # add the horizontal and vertical lines
            if truthvals != nothing
                append!(offdiag, vline)
                hline = layer(yintercept = truthvals[j], Geom.hline,
                              Theme(default_color = colorant"red"))
                append!(offdiag, hline)
            end

            x=histsamps
            y=samples[:, j][bins[j][1] .<= samples[:, j] .< bins[j][end]]

            # get a hexbin layer
            append!(offdiag, layer(x=x, y=y,
                                   Geom.hexbin(xbincount = hexbins[i],
                                               ybincount = hexbins[j])))

            # and add the axis labels if given
            if varnames != nothing

                # ylabels only along the side
                if i == 1
                    ylabel = String(varnames[j])
                else
                    ylabel = nothing
                end

                # xlabels only along the bottom
                if j == ndims
                    xlabel = String(varnames[i])
                else
                    xlabel = nothing
                end

            else
                xlabel = nothing
                ylabel = nothing
            end

            # and plot the layers
            subplots[j, i] = render(plot(offdiag...,
                                    Scale.color_continuous(colormap = Viridis.viridis),
                                    Guide.xlabel(xlabel), Guide.ylabel(ylabel),
                                    Coord.Cartesian(xmin = bins[i][1], xmax = bins[i][end],
                                                    ymin = bins[j][1], ymax = bins[j][end]),
                                    Theme(key_position = :none)))

            # make subplots above diagonal empty
            subplots[i, j] = Compose.context()
        end
    end
    gridstack(subplots)
end

end
