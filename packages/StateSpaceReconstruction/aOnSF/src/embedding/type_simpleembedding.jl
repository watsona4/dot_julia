

""" An embedding holding only its points and no information about the
construction of the embedding. """
mutable struct SimpleEmbedding{D, T} <: AbstractEmbedding{D, T}
    points::AbstractArray{T, 2}
end


export SimpleEmbedding
