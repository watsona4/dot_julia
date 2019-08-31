
"""
An embedding in which the last point is guaranteed to lie within the convex
hull of the preceding points.
"""
mutable struct LinearlyInvariantEmbedding{D, T} <: AbstractEmbedding{D, T}
    points::AbstractArray{T, 2}
    embeddingdata::EmbeddingData{D, T}
end


export LinearlyInvariantEmbedding
