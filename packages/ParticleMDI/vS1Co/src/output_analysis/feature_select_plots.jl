using Clustering
using LinearAlgebra
using Plots
using Plots.PlotMeasures

"""
`plot_pmdi_data(dataFile,
                psm::Posterior_similarity_matrix;
                k::Union{Int64, Nothing} = nothing,
                h::Union{Float64, Nothing} = nothing,
                orderby::Int64 = 0,
                featureSelectProbs = nothing)`

Generates a plot of a single raw data file, with the inferred clusters (as derived from the psm). If featureSelectProbs is supplied, features will be ordered according to the frequency they are selected in the model and the density of feature selection probabilities will be displayed along the margins.
## Input
- `psm` a posterior similarity matrix struct as output from `generate_psm`
- `k` optional - the number of clusters to highlight in the data
- `h` optional - the distance at which to cut the dendrogram. One of `k` or `h` must be specified.
- `orderby` observations in all plots are ordered in a way to separate clusters as well as possible. `orderby` specifies which dataset should be used to inform this ordering. `orderby = 0` will let the overall consensus dictate the ordering.
- `featureSelectProbs` optional - a vector of probabilities of length d, where dataFile is n x d. Each probability is the frequency a feature is selected as output from `pmdi()`.

## Output
- A heatmap of the data with clusters indicated.
"""
function plot_pmdi_data(data,
                        psm::Posterior_similarity_matrix;
                        k::Union{Int64, Nothing} = nothing,
                        h::Union{Float64, Nothing} = nothing,
                        orderby::Int64 = 0,
                        featureSelectProbs = nothing,
                        z_score::Bool = false)
  dataFile = deepcopy(data)
  if featureSelectProbs != nothing
    @assert length(featureSelectProbs) == size(dataFile, 2) "Feature selection vector is not the same length as the number of features"
  end
  if (z_score) & (typeof(dataFile) == Array{Float64, 2})
    sd = std(dataFile, dims = 1)
    dataFile .-= mean(dataFile, dims = 1)
    dataFile ./= sd
    dataFile .= floor.(Int64, dataFile)
    dataFile[dataFile .> 2] .= 2
    dataFile[dataFile .< - 2] .= - 2
  end


  # Extract clusters
  if orderby == 0
      orderby = size(psm.psm, 1)
  end
  hc = hclust(1 .- Symmetric(psm.psm[orderby], :L), linkage = :ward)
  if h == nothing
    cuts = cutree(hc, k = k)[hc.order]
  elseif k == nothing
    cuts = cutree(hc, h = h)[hc.order]
  end

  nclust = length(unique(cuts))
  ticks = indexin(1:nclust, cuts) .- 0.5
  sort!(ticks)
  ticks = ticks[2:end]
  order_rows = hc.order



  if featureSelectProbs != nothing
    order_cols = sortperm(featureSelectProbs, rev = true)
    fs_plot = Plots.bar(featureSelectProbs[order_cols] .* 243,
                        legend = false,
                        fill = "#000000",
                        linealpha = 0,
                        yflip = true,
                        ticks = false,
                        grid = false,
                        widen = false,
                        top_margin = - 7.5px,
                        right_margin = - 15px,
                        xlabel = "Features",
                        ylabel = "P(selected)")
    l = @layout [a{0.975w, 0.75h} b{0.025w, 0.75h}; c{0.975w, 0.25h} d{0.025w, 0.25h}]
  else
    l = @layout [a{0.975w, 0.75h} b{0.025w, 0.75h};]
    order_cols = 1:size(dataFile, 2)
  end

  clusters_matrix = Matrix{Int64}(undef, size(dataFile, 1), 1)
  clusters_matrix .= cuts

  clusters_plot = Plots.heatmap(clusters_matrix,
  legend = false,
  ticks = false,
  widen = false,
  c = :viridis,
  bottom_margin = -7.5px)
  hline!(ticks, c = "#000000")

  clusters_plot2 = Plots.heatmap(clusters_matrix,
  legend = false,
  ticks = false,
  widen = false,
  α = 0,
  top_margin = - 7.5px)

  data_plot = Plots.heatmap(dataFile[order_rows, order_cols],
  ticks = false,
  yflip = false,
  legend = false,
  widen = false,
  bottom_margin = -7.5px,
  ylabel = "Observations",
  c = :viridis,
  titlefont = Plots.font(family = "serif", pointsize = 12))
  hline!(ticks, linestyle = :dash, c = "#FFFFFF")

  if featureSelectProbs != nothing
    out = [data_plot, clusters_plot, fs_plot, clusters_plot2]
  else
    out = [data_plot, clusters_plot]
  end


    Plots.plot(out...,
    layout = l,
    link = :both,
    framestyle = :none,
    left_margin = - 15px,
    right_margin = - 10px,
    title_location = :left)
end
