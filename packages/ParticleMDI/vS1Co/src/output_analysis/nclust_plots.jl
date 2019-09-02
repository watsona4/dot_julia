using Plots

"""
`plot_phichain(outputfile::String, burnin::Int64, thin::Int64)`

Plots the phi values at each iteration resulting from pmdi output
## Input
- `outputFile::String` a string referring to the location on disk of pmdi output
- `burnin::Int64` an integer of the number of initial iterations to discard as burn-in
- `thin::Int64` an integer for the rate at which to thin output, `thin = 2` discards
every second iteration

## Output
Outputs a line plot of phi values resulting from pmdi output
"""

function get_nclust(outputFile::String, burnin::Int64 = 0, thin::Int64 = 1)
    outputNames = split(readline(outputFile), ',')
    K = sum(map(x -> occursin(r"MassParameter", x), outputNames))
    output = readdlm(outputFile, ',', header = false, skipstart = burnin + 1)
    hyperCols = Int64(K * (K - 1) / 2 + K + 1 + (K == 1))
    output = Matrix{Int64}(output[1:thin:end, (hyperCols + 1):end])
    n_obs = Int64((size(output, 2)) / K)
    dataNames = unique(map(x -> split(x, "_")[1], outputNames[(hyperCols + 1):end]))

    plot_matrix = Matrix{Int64}(undef, size(output, 1), K)

    for k in 1:K
        start_col = (1:n_obs:size(output, 2))[k]
        end_col = (n_obs:n_obs:size(output, 2))[k]
        for i in 1:size(output, 1)
            plot_matrix[i, k] = length(unique(output[i, start_col:end_col]))
        end
    end
    return plot_matrix, dataNames, K
end


function plot_nclust_hist(outputFile::String, burnin::Int64 = 0, thin::Int64 = 1)
    plot_matrix, dataNames, K = particleMDI.get_nclust(outputFile, burnin, thin)

    clust_range = (minimum(plot_matrix), maximum(plot_matrix))
    Plots.histogram(plot_matrix,
                    bins = clust_range[1]:clust_range[2],
                    layout = K,
                    color = [i for j = 1:1, i = 1:K],                    
                    legend = false,
                    title = [dataNames[i] for j = 1:1, i = 1:K],
                    titlefont = Plots.font(family = "serif", pointsize = 12))
end

function plot_nclust_chain(outputFile::String, burnin::Int64 = 0, thin::Int64 = 1)
    plot_matrix, dataNames, K = get_nclust(outputFile, burnin, thin)
    clust_range = (minimum(plot_matrix), maximum(plot_matrix))
    Plots.plot(plot_matrix,
                    legend = false,
                    layout = K,
                    color = [i for j = 1:1, i = 1:K],
                    title = [dataNames[i] for j = 1:1, i = 1:K],
                    titlefont = Plots.font(family = "serif", pointsize = 12))
end
