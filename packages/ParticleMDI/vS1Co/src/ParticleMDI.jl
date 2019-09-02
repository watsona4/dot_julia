module ParticleMDI
import Clustering.hclust
import Distributions
import NonUniformRandomVariateGeneration
import Plots
import Plots.PlotMeasures
import StatsBase


# Core code
include("pmdi.jl")
include("misc.jl")
include("update_hypers.jl")

# Datatype specific
include("datatypes/gaussian_cluster.jl")
include("datatypes/categorical_cluster.jl")
include("datatypes/binom_cluster.jl")
include("datatypes/negbinom_cluster.jl")

# Output analysis
include("output_analysis/acf_plots.jl")
include("output_analysis/phi_plots.jl")
include("output_analysis/nclust_plots.jl")
include("output_analysis/consensus_map.jl")
include("output_analysis/feature_select_plots.jl")



export pmdi,
        gaussian_normalise!, coerce_categorical,
        plot_phi_chain, plot_phi_matrix,
        plot_nclust_chain, plot_nclust_hist,
        plot_pmdi_data,
        generate_psm, consensus_map

end # module
