module EmbeddingsAnalysis

    using LinearAlgebra
    using Statistics
    using Languages
    using Word2Vec
    using ConceptnetNumberbatch
    using StatsBase
    using MultivariateStats
    using Distances
    using QuantizedArrays

    import Base: size
    import Word2Vec: analogy_words

    export conceptnet2wv,
           CompressedWordVectors,
           compressedwordvectors,
           compress,
           analogy_words,
           write2disk,
           similarity_order,
           pca_reduction

    include("defaults.jl")          # defaults
    include("conceptnet2wv.jl")     # convert ConceptNet to WordVectors
    include("cwv.jl")               # CompressedWordVectors
    include("write2disk.jl")        # save WordVectors to disk
    include("similarity_order.jl")  # preprocess WordVectors
    include("pca_reduction.jl")     # preprocess/reduce dimensionality of WordVectors

end # module
