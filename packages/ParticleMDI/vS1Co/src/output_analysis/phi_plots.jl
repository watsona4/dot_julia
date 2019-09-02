using Plots

"""
`plot_phimatrix(outputfile::String, burnin::Int64, thin::Int64)`

Plots the mean phi values resulting from pmdi output
## Input
- `outputFile::String` a string referring to the location on disk of pmdi output
- `burnin::Int64` an integer of the number of initial iterations to discard as burn-in
- `thin::Int64` an integer for the rate at which to thin output, `thin = 2` discards
every second iteration

## Output
Outputs a heatmap of pairwise dataset Φ values
"""
function get_phi(outputFile::String, burnin::Int64 = 0, thin::Int64 = 0)
    outputNames = split(readline(outputFile), ',')
    phiColumns = map(outputNames) do str
        occursin(r"phi_", str)
    end
    output = readdlm(outputFile, ',', header = false, skipstart = burnin + 1)

    phiValues = Matrix{Float64}(output[1:thin:end, phiColumns])
    return phiValues
end


function plot_phi_matrix(outputFile::String, burnin::Int64 = 0, thin::Int64 = 1)
    phi_values = particleMDI.get_phi(outputFile, burnin, thin)
    K = Int64(0.5 + sqrt(8 * size(phi_values, 2) + 1) * 0.5)
    @assert K > 1 "Φ not inferred for no. of datasets = 1"
    phi_matrix = Matrix{Float64}(undef, K, K)
    phi_matrix .= NaN

    i = 1
    for k1 = 1:(K - 1)
        for k2 = (k1 + 1):K
            phi_matrix[k1, k2] = phi_matrix[k2, k1] = Statistics.mean(phi_values[:, i])
            i += 1
        end
    end

    Plots.heatmap(["phi (., $i)" for i = 1:K],
                  ["phi ($i, .)" for i = 1:K],
                  phi_matrix,
                  yflip = true,
                  c = :viridis,
                  clim = (0, maximum(phi_matrix)),
                  aspect_ratio = 1)
    # spy(phiMatrix,
    # Guide.xticks(ticks = [1:K;]),
    # Guide.yticks(ticks = [1:K;]),
    # Guide.xlabel("Φ(x, ⋅)"),
    # Guide.ylabel("Φ(⋅, y)"),
    # Scale.color_continuous_gradient(colormap = Scale.lab_gradient("#440154", "#1FA187", "#FDE725")))
end



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
function plot_phi_chain(outputFile::String, burnin::Int64, thin::Int64)
    phi_values = get_phi(outputFile, burnin, thin)
    n_phis = size(phi_values, 2)
    K = Int64(0.5 + sqrt(8 * size(phi_values, 2) + 1) * 0.5)
    @assert K > 1 "Φ not inferred for no. of datasets = 1"
    phi_names = ["phi ($i, $j)" for i = 1:(K - 1) for j = (i + 1):K]
    Plots.plot(phi_values,
               layout = n_phis,
               legend = false,
               colour = [i for j = 1:1, i = 1:n_phis],
               ylims = [0, maximum(phi_values)],
               title = [phi_names[i] for j = 1:1, i = 1:n_phis],
               titlefont = Plots.font(family = "serif", pointsize = 12))

    # plot(melt(phiValues), x = :Iteration, y = :value, color = :variable,
    # Geom.line,
    # Guide.xlabel("Iteration"),
    # Guide.ylabel("Φ"),
    # Coord.Cartesian(xmax = maximum(phiValues[:Iteration])))
end
