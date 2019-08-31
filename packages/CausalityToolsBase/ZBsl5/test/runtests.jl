using Test
using CausalityToolsBase, StaticArrays, DelayEmbeddings

include("test_bin_encode.jl")
include("test_kerneldensity.jl")
include("test_mutualinfo.jl")
include("test_histograms.jl")
include("test_custom_reconstruction.jl")
include("test_optimal_embedding_params.jl")
include("test_binnings.jl")
include("test_generate_gridpoints.jl")