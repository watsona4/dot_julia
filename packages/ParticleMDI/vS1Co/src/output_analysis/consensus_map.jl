using Clustering
using LinearAlgebra
using Plots
using Plots.PlotMeasures

mutable struct Posterior_similarity_matrix
    psm::Vector
    names::Vector{String}
    Posterior_similarity_matrix(K, n_obs) = new([Matrix(1.0I, n_obs, n_obs) for k in 1:(K + (K > 1))],
                                                Vector{String}(undef, K + (K > 1)))
end


"""
`generate_psm(outputFile::String, burnin::Int64 = 0, thin::Int64 = 1)`

Generates a posterior similarity matrix from pmdi output
## Input
- `outputFile::S    tring` a string referring to the location on disk of pmdi output
- `burnin::Int64` an integer of the number of initial iterations to discard as burn-in
- `thin::Int64` an integer for the rate at which to thin output, `thin = 2` discards
every second iteration

## Output
A struct of class `Posterior_similarity_matrix` containing:
    - `psm` K n × n matrices where element (i, j) measures how frequently observation
    i and j are co-clustered in dataset k. If `K > 1` an overall consensus matrix
    is also included which is an element-wise average of the K other matrices
    - `names` a vector of the dataset names
"""
function generate_psm(outputFile::String, burnin::Int64 = 0, thin::Int64 = 1)
    outputNames = split(readline(outputFile), ',')
    output = readdlm(outputFile, ',', header = false, skipstart = burnin + 1)
    K = sum(map(outputNames) do str
        occursin(r"MassParameter", str)
    end)

    output = output[1:thin:end, (K + binomial(K, 2) + (K == 1) + 2):end]

    n_obs = size(output, 2) / K
    @assert mod(n_obs, 1) == 0 "Error: Datasets have different number of observations"
    n_obs = Int64(n_obs)
    n_iter = size(output, 1)

    psm = Posterior_similarity_matrix(K, n_obs)
    psm.names[1:K] = unique(map(x -> split(x, '_')[1], outputNames[(K + (K == 1) + binomial(K, 2) + 2):end]))
    if K > 1
        psm.names[K + 1] = "Overall"
    end
    for k = 1:K
        for j = 1:(n_obs - 1)
            for i = (j + 1):n_obs
                psm.psm[k][i, j] = sum(output[:, i + n_obs * (k - 1)] .== output[:, j + n_obs * (k - 1)]) / n_iter
            end
        end
    end
    if K > 1
        for k = 1:K
            psm.psm[K + 1] += psm.psm[k] / K
        end
            psm.psm[K + 1][diagind(psm.psm[K + 1])] .= 1.0
    end

    return psm
end

function generate_psm2(output, K, n_obs)
    output = output[(K + binomial(K, 2) + (K == 1) + 2):end]

    n_iter = size(output, 1)

    psm = Posterior_similarity_matrix(K, n_obs)
    for k = 1:K
        for j = 1:(n_obs - 1)
            for i = (j + 1):n_obs
                psm.psm[k][i, j] = sum(output[i + n_obs * (k - 1)] .== output[j + n_obs * (k - 1)]) / n_iter
            end
        end
    end
    if K > 1
        for k = 1:K
            psm.psm[K + 1] += psm.psm[k] / K
        end
            psm.psm[K + 1][diagind(psm.psm[K + 1])] .= 1.0
    end
    return psm
end

"""
`get_consensus_allocations(psm::Posterior_similarity_matrix, nclust::Int64, orderby::Int64 = 0)`
"""
function get_consensus_allocations(psm::Posterior_similarity_matrix, nclust::Int64, orderby::Int64 = 0)
    if orderby == 0
        orderby = size(psm.psm, 1)
    end
    hc = hclust(1 .- Symmetric(psm.psm[orderby], :L), linkage = :ward, uplo = :L)
    return cutree(hc, k = nclust)
end


"""
`consensus_map(psm::Posterior_similarity_matrix; k::Union{Int64, Nothing} = nothing,
h::Union{Float64, Nothing} = nothing,
orderby::Int64 = 0)`

Generates a consensus map plot for a given posterior similarity matrix
## Input
- `psm` a posterior similarity matrix struct as output from `generate_psm`
- `k` optional - the number of clusters to highlight in the data
- `h` optional - the distance at which to cut the dendrogram. One of `k` or `h` must be specified.
- `orderby` observations in all plots are ordered in a way to separate clusters as well
as possible. `orderby` specifies which dataset should be used to inform this ordering.
`orderby = 0` will let the overall consensus dictate the ordering.
## Output
- K + 1 (or K if K == 1) consensus maps illustrating the clustering output in each
of K datasets.
"""
function consensus_map(psm::Posterior_similarity_matrix;
                       k::Union{Int64, Nothing} = nothing,
                       h::Union{Float64, Nothing} = nothing,
                       orderby::Int64 = 0)
    @assert (k != nothing) | (h != nothing) "You must specify either k (number of clusters) or h (height to cut dendrogram)"
    if (orderby == 0) | (orderby == - 1)
        orderby_main = size(psm.psm, 1)
    else orderby_main = orderby
    end
    hc = hclust(1 .- Symmetric(psm.psm[orderby_main], :L), linkage = :ward)
    if h == nothing
        cuts = cutree(hc, k = k)[hc.order]
    elseif k == nothing
        cuts = cutree(hc, h = h)[hc.order]
    end
    nclust = length(unique(cuts))
    ticks = indexin(1:nclust, cuts) .- 0.5
    sort!(ticks)
    append!(ticks, size(psm.psm[1], 1) + 0.5)
    # Surely a better way of doing this
    ticks1 = [[ticks[i], ticks[i+1], NaN][j] for i = 1:nclust for j = 1:3]
    ticks2 = [[ticks[i], ticks[i], NaN][j] for i = 1:nclust for j = 1:3]
    ticks3 = [[ticks[i], ticks[i], NaN][j] for i = 2:(nclust + 1) for j = 1:3]
    K = length(psm.psm)
    if (K > 1) & (orderby != - 1)
        plots = [Plots.heatmap(Symmetric(psm.psm[k], :L)[hc.order, hc.order],
                        ticks = false,
                        yflip = false,
                        title = psm.names[k],
                        legend = false,
                        aspect_ratio = 1,
                        c = :viridis,
                        clim = (0, 1),
                        titlefont = Plots.font(family = "serif", pointsize = 12)) for k in [K; 1:max(K - 1, 1)]]
        l = @layout [a{0.8w} grid(max(K - 1, 1), 1)]
    elseif (K > 1) & (orderby == - 1)
        plot_order = [hclust(1 .- Symmetric(psm.psm[k], :L), linkage = :ward).order for k in 1:K]
        plots = [Plots.heatmap(Symmetric(psm.psm[k], :L)[plot_order[k], plot_order[k]],
                        ticks = false,
                        yflip = false,
                        title = psm.names[k],
                        legend = false,
                        aspect_ratio = 1,
                        c = :viridis,
                        clim = (0, 1),
                        titlefont = Plots.font(family = "serif", pointsize = 12)) for k in [K; 1:max(K - 1, 1)]]
        l = @layout [a{0.8w} grid(max(K - 1, 1), 1)]
    elseif K == 1
        plots = [Plots.heatmap(Symmetric(psm.psm[1], :L)[hc.order, hc.order],
                        ticks = false,
                        yflip = false,
                        title = psm.names[1],
                        legend = false,
                        aspect_ratio = 1,
                        c = :viridis,
                        titlefont = Plots.font(family = "serif", pointsize = 12))]
        l = @layout [a;]
    end



    Plots.plot(plots..., layout = l,
               left_margin= -5px,
               right_margin = -5px,
               bottom_margin = -5px,
               top_margin = -5px,
               title_location = :left)
    plot!(ticks1, ticks2, seriestype = :path, c = "#FFFFFF", linestyle = :dash)
    plot!(ticks1, ticks3, seriestype = :path, c = "#FFFFFF", linestyle = :dash)
    plot!(ticks2, ticks1, seriestype = :path, c = "#FFFFFF", linestyle = :dash)
    plot!(ticks3, ticks1, seriestype = :path, c = "#FFFFFF", linestyle = :dash,
    widen = false)

end
