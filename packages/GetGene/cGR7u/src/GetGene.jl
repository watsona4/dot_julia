__precompile__()

module GetGene

using HTTP, LazyJSON, DataFrames

export
    getgenes,
    getgeneinfo

include("getgenes.jl")

end
