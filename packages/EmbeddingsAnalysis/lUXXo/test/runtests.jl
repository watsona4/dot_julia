module TestEmbeddingsAnalysis

using Test
using LinearAlgebra
using Random
using EmbeddingsAnalysis
using Word2Vec
using ConceptnetNumberbatch
using Distances
using QuantizedArrays

include("write2disk.jl")
include("conceptnet2wv.jl")
include("cwv.jl")
include("similarity_order.jl")
include("pca_reduction.jl")

end
