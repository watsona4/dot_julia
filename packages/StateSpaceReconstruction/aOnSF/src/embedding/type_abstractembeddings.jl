import Base.minimum, Base.maximum

"""
    AbstractEmbedding{D, T}

Abstract state space embedding.
"""
abstract type AbstractEmbedding{D, T} end


@inline Base.length(r::AbstractEmbedding) = length(r.points)

"""
    size(E::AbstractEmbedding) -> (Int, Int)

Get the size of the embedding, which is `(dim, npoints)`.
"""
@inline Base.size(r::AbstractEmbedding{D,T}) where {D,T} = (D, length(r.points))
@inline Base.size(r::AbstractEmbedding, i) = size(r.points)[i]

tps = Union{SVector{D, T} where {D, T}, Colon, UnitRange{Int}, AbstractVector{Int}}
@inline Base.getindex(r::AbstractEmbedding, i::Int) = r.points[:, i]
@inline Base.getindex(r::AbstractEmbedding, i::tps) = r.points[:, i]
@inline Base.getindex(r::AbstractEmbedding, i::Int, j::tps) = r.points[j, i]
@inline Base.getindex(r::AbstractEmbedding, i::tps, j::tps) = r.points[j, i]
@inline Base.getindex(r::AbstractEmbedding, i::Int, j::Colon) = r.points[i]
@inline Base.getindex(r::AbstractEmbedding, i::tps, j::Colon) = r.points[:, i]
@inline Base.getindex(r::AbstractEmbedding, i::Colon, j::Int) = r.points[j, :]
@inline Base.getindex(r::AbstractEmbedding, i::Colon, j::Colon) = r.points
@inline Base.getindex(r::AbstractEmbedding, i::Colon, j::tps) = r.points[j, i]

#Base.unique(r::AbstractEmbedding) = unique(r.points)
#Base.unique(r::AbstractEmbedding, i::Int) = unique(r.points, dims = i)

dimension(::AbstractEmbedding{D,T}) where {D,T} = D
@inline Base.eltype(r::AbstractEmbedding{D,T}) where {D,T} = T

import Base: ==
==(r₁::AbstractEmbedding, r₂::AbstractEmbedding) =
    r₁.points == r₂.points

"""
    npoints(E::AbstractEmbedding) -> Int

Get the dimension the number of points in the embedding.
"""
npoints(r::AbstractEmbedding) = size(r.points, 2)

"""
    points(E::AbstractEmbedding) -> Int

Get the points of the embedding.
"""
points(r::AbstractEmbedding) = r.points

"""
    get_dataseries(E::AbstractEmbedding) -> Vector{Vector{T}} where {T<:Number}

Return the data series that was used for the embedding.
"""
get_dataseries(r::AbstractEmbedding) = r.embeddingdata.dataseries

"""
    get_dataseries(E::AbstractEmbedding) -> Vector{Vector{T}} where {T<:Number}

Return the i-th dataseries that was used for the embedding.
"""
get_dataseries(E::AbstractEmbedding, i::Int) = E.embeddingdata.dataseries[i]
series = get_dataseries


"""
    which_series(E::AbstractEmbedding, i::Int)

Return the index of the data series appear in the `i`-th column
of the embedding.

## Example
Assume `r` is a `Embedding` instance, then
`which_series(r, 2) = 1` indicates that the second column of
the embedding is populated by a lagged instance of the 1st
data series.
"""
which_series(E::AbstractEmbedding, i::Int) = E.embeddingdata.in_which_pos[i]

"""
    in_which_pos(E::AbstractEmbedding) -> EmbeddingPositions

Return the data series that went into the embedding.
"""
in_which_pos(E::AbstractEmbedding) = E.embeddingdata.in_which_pos

"""
    at_what_lags(E::AbstractEmbedding) -> Vector{Vector{T}} where {T<:Number}

Return the data series that went into the embedding.
"""
at_what_lags(E::AbstractEmbedding) = E.embeddingdata.at_what_lags

#####################################################
# Retrieve information about the embedding.
#####################################################
"""
    n(E::AbstractEmbedding) -> Int

How many points are there in the embedding?
"""
n(E::AbstractEmbedding) = size(E.points, 2)

"""
    lags(E::AbstractEmbedding) -> EmbeddingLags

What is the embedding lag for each of the variables/columns
of the embedding?
"""
lags(E::AbstractEmbedding) = at_what_lags(E)

"""
    lag(E::AbstractEmbedding, i::Int) -> Int

What is the embedding lag for the i-th variable/column
of the embedding?
"""
lag(E::AbstractEmbedding, i::Int) = E.at_what_lags[i]

"""
    label(E::AbstractEmbedding, i::Int) -> String

Get the description label of the i-th time series that went
into the embedding.

"""
label(E::AbstractEmbedding, i::Int) = E.embeddingdata.labels[i]
"""
    labels(E::AbstractEmbedding) -> Vector{String}

Get the descriptions of the all time series that went
into the embedding.
"""
labels(E::AbstractEmbedding) = E.embeddingdata.labels


"""
    minimum(r::AbstractEmbedding{D, T}) where {D, T}) -> T

Finds the minimum value in an Embedding.
"""
minimum(E::AbstractEmbedding{D, T}) where {D, T} = minimum(E.points)

"""
    maximum(r::AbstractEmbedding{D, T}) where {D, T}) -> T

Find the maximum value in a Embedding.
"""
maximum(E::AbstractEmbedding{D, T}) where {D, T} = maximum(E.points)


"""
    minima(r::Embedding) where {D, T}) -> `SVector{D, T}`

Returns the minima of the embedding along each axis.
"""
minima(E::AbstractEmbedding{D, T}) where {D, T} = [minimum(E[i, :]) for i = 1:D]

"""
    maxima(r::Embedding{D, T}) where {D, T}) -> `SVector{D, T}`

Returns the maxima of the embedding along each axis.
"""
maxima(E::AbstractEmbedding{D, T}) where {D, T} = [maximum(E[i, :]) for i = 1:D]


export
AbstractEmbedding,
label, labels,
lag, lags,
n,
at_what_lags,
in_which_pos,
which_series,
get_dataseries,
points,
npoints,
dimension
