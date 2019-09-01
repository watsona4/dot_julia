"""
    extract_peak_interval(run; α, n)

Takes a CoulterCounterRun `run` and fits a kernel density estimate to smooth
out binning effects by the machine and then finds the largest peak. It returns
the diameter corresponding to the location of this peak as well as the max and
min diameters of the confidence interval defined by `α`. This interval is
generated on the empirically by bootstrapping the data `n` times.
"""
function extract_peak_interval(run::CoulterCounterRun; α=0.05, n=250)
    alloc = zeros(length(run.data))
    results = zeros(n)
    orig_est = extract_peak(run.data)
    for i in 1:n
        sample!(run.data, alloc)
        results[i] = extract_peak(alloc)
    end
    sort!(results[.!isnan.(results)])
    # update n since we might have deleted some values due to NaNs
    n = length(results)

    orig_est, max(orig_est, results[ceil(Int, (1-α/2)*n)]), min(orig_est, results[floor(Int, (α/2)*n+1)])
end




"""
    _find_peaks(xs, ys; minx, miny)

Finds prominent peaks in `ys` and returns the values from `xs` corresponding to
the location of these peaks. `minx` and `miny` can be used to exclude peaks that
are too small in `x` or `y`.
"""
function _find_peaks(xs::Array{T}, ys::Array{T}; minx=310, miny=0.0005) where T
    loc = zero(T) # location of an extremum
    width = zero(T) # width of an extremum
    sign = -1
    extrema = T[]
    heights = T[miny]
    is_peak = Bool[]
    for i in 2:length(ys)
        if ys[i] > ys[i-1]
            if sign < 0 && width > 0
                push!(extrema, loc/width)
                push!(heights, ys[i-1])
                push!(is_peak, false)
                loc = 0
                width = 0
            end
            loc = xs[i]
            width = 1
            sign = 1
        elseif ys[i] == ys[i-1]
            loc += xs[i]
            width += 1
        elseif ys[i] < ys[i-1]
            if sign > 0 && width > 0
                push!(extrema, loc/width)
                push!(heights, ys[i-1])
                push!(is_peak, true)
                loc = 0
                width = 0
            end
            loc = xs[i]
            width = 1
            sign = -1
        end
    end

    for i in 2:length(is_peak)
        # This should only be triggered if a peak is not followed by a valley, or vice versa
        if !xor(is_peak[i], is_peak[i-1])
            @warn("Unable to establish prominence. Peak identification potentially flawed.")
            break
        end
    end

    push!(heights, miny)

    peaks = T[]
    # peaks are every second value in heights
    for i in 2:2:length(heights)-1
        # peak shows significant prominence versus their adjacent vallies
        if abs(log2(heights[i]./heights[i-1])+log2(heights[i]./heights[i+1])) .> 0.5
            if extrema[i-1] > minx && heights[i] > miny
                push!(peaks, extrema[i-1])
            end
        end
    end
    if length(peaks) > 1
        @warn("Multiple viable peaks identified: $(join(peaks, ", "))")
    end
    peaks
end

function extract_peak(data::Array)
    kd_est = kde(data)
    _find_peaks(collect(kd_est.x), kd_est.density)[end]
end

extract_peak(run::CoulterCounterRun) = extract_peak(run.data)

theme = Theme(background_color=colorant"white", panel_stroke=colorant"black",
    grid_color=colorant"Gray", line_width=.7mm,
    major_label_font_size=14pt, minor_label_font_size=11pt,
    minor_label_color=colorant"black", major_label_color=colorant"black",
key_title_color=colorant"black", key_label_color=colorant"black", key_title_font_size=13pt,
key_label_font_size=10pt);

function extract_peak!(run::CoulterCounterRun; folder="raw_coulter_graphs")
    mkpath(folder)
    kd_est = kde(run.data)
    peaks = _find_peaks(collect(kd_est.x), kd_est.density)
    # dumb solution for now
    run.livepeak = peaks[end]
    run.allpeaks = peaks

    xmins = run.binlims[1:end-1]
    xmaxs = run.binlims[2:end]

    raw = layer(xmin=xmins,
                xmax=xmaxs,
                y=run.binheights./sum((xmaxs .- xmins) .* run.binheights),
                Geom.bar, theme)
    est = layer(x=kd_est.x,
                y=kd_est.density,
                Geom.line,
                Theme(default_color=colorant"orange", theme))
    plot_peaks = [layer(xintercept=[run.livepeak],
                        Geom.vline,
                        Theme(default_color=colorant"red", theme))
                 ]
    if length(run.allpeaks) > 0
        push!(plot_peaks, layer(xintercept=filter(x-> x ≠ run.livepeak, run.allpeaks),
                                Geom.vline,
                                Theme(default_color=colorant"gray", theme)))
    end
    # Round up to the nearest hundred fL that includes the lower 98th percentile of data
    xlimmax = ceil(percentile(run.data, 98), digits=-2)
    time = run.reltime != nothing ? run.reltime : run.timepoint
    p = plot(plot_peaks..., est, raw, theme,
             Coord.cartesian(xmin=50, xmax=xlimmax),
             Guide.xticks(ticks=collect(0:100:xlimmax)),
             Guide.xlabel("Volume (fL)"), theme,
             Guide.title("$time [$(run.sample)]"),
             Guide.manual_color_key("Legend", ["Raw Coulter data", "KDE fit", "Called live peak", "Other peaks"], ["deepskyblue", "orange", "red", "gray"])
    )

    filename = split(run.filename, ".=#Z2")[1]
    filepath = joinpath("raw_coulter_graphs", "$filename.svg")
    draw(SVG(filepath, 17cm, 10cm), p)
end
