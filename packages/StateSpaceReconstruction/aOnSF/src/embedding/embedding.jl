
"""
    Embedding{D, T}

An immutable type representing a state space embedding.
Assume `r` is a embedding, then

* `r.points` gives the embeded  state vectors
* `r.embeddingdata` returns the recon
* series that was used to make the embedding, ``

"""
mutable struct Embedding{D, T} <: AbstractEmbedding{D, T}
    points::AbstractArray{T, 2}
    embeddingdata::EmbeddingData{D, T}
end
