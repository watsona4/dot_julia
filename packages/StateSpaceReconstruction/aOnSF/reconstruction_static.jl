"""
    AbstractEmbedding{D, T}

Abstract state space embedding.
"""
abstract type AbstractEmbedding{D, T} end

#####################################################
# Simple immutable type to store embedding lags.
#####################################################
struct EmbeddingLags
    lags::Vector{Int}
end

Base.getindex(rl::EmbeddingLags,
            i::Union{Int, Colon, UnitRange, Vector{Int}}) =
    Base.getindex(rl.lags, i)

#####################################################
# Simple immutable type to store embedding positions
#####################################################
"""
     EmbeddingPositions

Assume `r` is a `Embedding` instance.
Stores the information on which of the data series in
`r.which_dataseries`

"""
struct EmbeddingPositions
    positions::Vector{Int}
end

Base.getindex(rp::EmbeddingPositions,
            i::Union{Int, Colon, UnitRange, Vector{Int}}) =
    Base.getindex(rp.positions, i)


#####################################################
# Immutable type to store the data series that went
# into the embedding.
#####################################################
"""
    EmbeddingData{N, T}

The data and parameters that goes into a embedding.
Assume `rd` is a `EmbeddingData` instance. Then

* `rd.dataseries` gives a vector of dataseries (each itself being
a vector) that was used for the embedding.
* `rd.in_which_pos` indicates which of the dataseries appear in which
columns of the embedding. For example, `rd.in_which_pos[2] = 3` means
that the 3rd timeseries (which can accessed by `rd.dataseries[3]`)
appears in the second column of the embedding.
* `rd.at_what_lags[i]` gives the lags in the i-th column of the embedding.
* `rd.labels[i]` returns the label of the i-th dataseries
* `rd.descriptions[i]` returns the description of the i-th dataseries.
"""
struct EmbeddingData{N, T}
    dataseries::Vector{Vector{T}}
    labels::Vector{String}
    descriptions::Vector{String}
    in_which_pos::EmbeddingPositions
    at_what_lags::EmbeddingLags
end


#####################################################
# Embedding type.
#####################################################
"""
    Embedding{D, T}

An immutable type representing a state space embedding.
Assume `r` is a embedding, then

* `r.points` gives the embeded  state vectors
* `r.embeddingdata` returns the recon
* series that was used to make the embedding, ``

"""
struct Embedding{D, T} <: AbstractEmbedding{D, T}
    points::Dataset{D, T}
    embeddingdata::EmbeddingData
end


@inline Base.length(r::AbstractEmbedding) = length(r.points)

"""
    size(E::AbstractEmbedding) -> (Int, Int)

Get the size of the embedding, which is `(npoints, dim)`.
"""
@inline Base.size(r::AbstractEmbedding{D,T}) where {D,T} = (length(r.points), D)
@inline Base.size(r::AbstractEmbedding, i) = size(r.points)[i]

tps = Union{SVector{D, T} where {D, T}, Colon, UnitRange{Int}, AbstractVector{Int}}
@inline Base.getindex(r::AbstractEmbedding, i::Int) = r.points[i]
@inline Base.getindex(r::AbstractEmbedding, i::tps) = r.points[i]
@inline Base.getindex(r::AbstractEmbedding, i::Int, j::tps) = r.points[i, j]
@inline Base.getindex(r::AbstractEmbedding, i::tps, j::tps) = r.points[i, j]
@inline Base.getindex(r::AbstractEmbedding, i::Int, j::Colon) = r.points[i]
@inline Base.getindex(r::AbstractEmbedding, i::tps, j::Colon) = r.points[i]
@inline Base.getindex(r::AbstractEmbedding, i::Colon, j::Int) = r.points[i, j]
@inline Base.getindex(r::AbstractEmbedding, i::Colon, j::Colon) = r.points
@inline Base.getindex(r::AbstractEmbedding, i::Colon, j::tps) = r.points[i, j]

Base.unique(r::AbstractEmbedding) = Base.unique(r.points.data)
Base.unique(r::AbstractEmbedding, i::Int) = Base.unique(r.points.data, dims = i)

dimension(::AbstractEmbedding{D,T}) where {D,T} = D
@inline Base.eltype(r::AbstractEmbedding{D,T}) where {D,T} = Ti

import Base: ==
==(r₁::AbstractEmbedding, r₂::AbstractEmbedding) =
    r₁.points == r₂.points

"""
    npoints(E::AbstractEmbedding) -> Int

Get the dimension the number of points in the embedding.
"""
npoints(r::AbstractEmbedding) = length(r.points)

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
n(E::AbstractEmbedding) = length(E.points)

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

import Base.minimum, Base.maximum
import DynamicalSystemsBase.minima
import DynamicalSystemsBase.maxima

"""
    minimum(d::Dataset{D, T} where {D, T}) -> T

Finds the minimum value in a Dataset.
"""
minimum(d::Dataset{D, T}) where {D, T} = minimum(minima(d))

"""
    maximum(d::Dataset{D, T} where {D, T}) -> T

Finds the maximum value in a Dataset.
"""
maximum(d::Dataset{D, T}) where {D, T} = maximum(maxima(d))

"""
    minimum(r::Embedding{D, T}) where {D, T}) -> T

Finds the minimum value in a Dataset.
"""
minimum(r::AbstractEmbedding{D, T}) where {D, T} = minimum(r.points)

"""
    maximum(r::Dataset{D, T}) where {D, T}) -> T

Find the maximum value in a Dataset.
"""
maximum(r::AbstractEmbedding{D, T}) where {D, T} = maximum(r.points)


"""
    minima(r::Embedding) where {D, T}) -> `SVector{D, T}`

Returns an `SVector` containing the maxima of the embedding along
each axis.
"""
minima(r::AbstractEmbedding{D, T}) where {D, T} = minima(r.points)

"""
    maxima(r::Embedding{D, T}) where {D, T}) -> `SVector{D, T}`

Returns an `SVector` containing the maxima of the embedding along
each axis.
"""
maxima(r::AbstractEmbedding{D, T}) where {D, T} = maximum(r.points)


"""
    embed(ts::Vector{Vector{T}}, in_which_pos::Vector{Int},
                at_what_lags::Vector{Int}) where T <: Number ->
                Embedding

Perform a state space embedding of the vectors in `ts`.

## Arguments
1. `which_ts::Vector{Vector{T}} where T <: Number`. Contains the the time
    series to embed.
2. `in_which_pos::Vector{Int}``. The length of in_which_pos gives the dimension
    of the embedding. The value of the ith element of in_which_pos indicates
    which time series in the ith column of the embedding.
    - **Example 1**: if `which_ts = [ts1, ts2]`, then we index ts1 as 1 and
        ts2 as 2. Setting `in_which_pos = [2, 2, 1]` will result in a
        3-dimensional embedding where `ts2` will appear in columns 1 and 2,
        while `ts1` will appear in column 3.
    - **Example 2**: If `which_ts = [ts1, ts2, ts3]`, then
        `in_which_pos = [2, 1, 2, 3, 3]` results in a 5-dimensional embedding
        where `ts1`appears in column 2, `ts2` appears in columns 1 and 3, while
        `ts3`appears in columns 4 and 5.
3. `at_what_lags::Vector{Int}` sets the lag in each column. Must be the same
    length as `which_ts`.
    - **Example**: if `in_which_pos = [2, 2, 1]`, then
        `at_what_lags = [1, 0, -1]` means that the lag in column 1 is 1, the
        lag in the second column is 0 and the lag in the third column is -1.
"""
function embed(ts::Vector{Vector{T}},
               in_which_pos::Vector{Int},
               at_what_lags::Vector{Int};
                 labels::Vector{String} = ["" for x in 1:length(ts)]) where {T<:Number}
    dim = length(in_which_pos)
    minlag, maxlag = minimum(at_what_lags), maximum(at_what_lags)
    npts = length(ts[1]) - (maxlag + abs(minlag))
    E = zeros(T, dim, npts)

    for i in 1:length(in_which_pos)
        ts_ind = in_which_pos[i]
        TS = ts[ts_ind]
        lag = at_what_lags[i]

        if lag > 0
            E[i, :] = TS[((1 + abs(minlag)) + lag):(end - maxlag) + lag]
        elseif lag < 0
            E[i, :] = TS[((1 + abs(minlag)) - abs(lag)):(end - maxlag - abs(lag))]
        elseif lag == 0
            E[i, :] = TS[(1 + abs(minlag)):(end - maxlag)]
        end
    end
    N = length(ts)
    embeddingdata = EmbeddingData{N, T}(
        ts,  # the dataseries
        ["" for i = 1:length(ts)], # empty labels by default
        ["" for i = 1:length(ts)], # empty descriptions by default
        EmbeddingPositions(in_which_pos), # the positions in which the dataseries appear
        EmbeddingLags(at_what_lags) # the embedding lag for each column
        )
    Embedding(Dataset(transpose(E)), embeddingdata)
end


"""
    embed(A::AbstractArray)

Returns an embedding of a vector of vectors, treating each
vector as a dynamical variable. Zero lag is used for all the
columns.
"""
function embed(ts::Vector{Vector{T}}) where {T}
    D = length(ts)
    embed(ts, [i for i = 1:D], [0 for i in 1:D])
end

"""
    embed(A::AbstractArray)

Returns an embedding of an array, treating each
column as a dynamical variable. Zero lag is used
for all the columns.
"""
function embed(A::AbstractArray{T}) where {T}
    D = size(A, 2)
    embed([A[:, i] for i = 1:D],
            [i for i = 1:D],
            [0 for i in 1:D])
end

"""
    embed(d::AbstractArray{T, 2},
                    in_which_pos::Vector{Int},
                    at_what_lags::Vector{Int})

Embedding of data represented by an array. Each
column of the array must correspond to one data series.
"""
function embed(data::AbstractArray{T, 2},
                    in_which_pos::Vector{Int},
                    at_what_lags::Vector{Int}) where {T}
    D = size(data, 2)
    embed(
        [data[:, i] for i = 1:D],
        in_which_pos,
        at_what_lags
    )
end

Embedding(ts::Vector{Vector{T}},
               in_which_pos::Vector{Int},
               at_what_lags::Vector{Int}) where {T} =
               embed(ts, in_which_pos, at_what_lags)

function Embedding(v::Vector{Vector{T} where T})
    positions = [i for i in 1:length(v)]
    lags = [0 for i in 1:length(v)]
    embed(v, positions, lags)
end


"""
     embed(d::Dataset)

Returns a state space embedding of the column of `d`.
"""
function embed(d::Dataset)
    D = size(d, 2)
    embed([d[:, i] for i = 1:D])
end

"""
     embed(d::Dataset,
        in_which_pos::Vector{Int},
        at_what_lags::Vector{Int})

Returns a state space embedding of the column of `d`.

## Arguments
* `d::Dataset`: The columns of `d` contains the data series to use
    for the embedding.
* `in_which_pos::Vector{Int}``. The length of in_which_pos gives the dimension
    of the embedding. The value of the ith element of `in_which_pos`
    indicates which column of `d` goes in the i-th column of the embedding.
* `at_what_lags::Vector{Int}` sets the lag in each column of the reconstrution.
    Must be the same length as `dimension(d)`
    - **Example**: if `in_which_pos = [2, 2, 1]`, then
        `at_what_lags = [1, 0, -1]` means that the lag in column 1 is 1, the
        lag in the second column is 0 and the lag in the third column is -1.
"""
function embed(d::Dataset,
        in_which_pos::Vector{Int},
        at_what_lags::Vector{Int})
    embed(
        [d[:, i] for i = 1:DynamicalSystemsBase.dimension(d)],
        in_which_pos,
        at_what_lags
    )
end

function Embedding(d::Dataset,
        in_which_pos::Vector{Int},
        at_what_lags::Vector{Int})
    embed(
        [d[:, i] for i = 1:DynamicalSystemsBase.dimension(d)],
        in_which_pos,
        at_what_lags
    )
end

########################################
# SArrays and SVectors
########################################
function embed(ts::Vector{SVector{N, T}},
        in_which_pos::Vector{Int},
        at_what_lags::Vector{Int};
        labels::Vector{String} =  ["" for x in 1:length(ts)]) where {N, T}
    dim = length(in_which_pos)
    minlag, maxlag = minimum(at_what_lags), maximum(at_what_lags)
    npts = length(ts[1]) - (maxlag + abs(minlag))
    E = zeros(T, dim, npts)

    for i in 1:length(in_which_pos)
        ts_ind = in_which_pos[i]
        TS = ts[ts_ind]
        lag = at_what_lags[i]

        if lag > 0
            E[i, :] = TS[((1 + abs(minlag)) + lag):(end - maxlag) + lag]
        elseif lag < 0
            E[i, :] = TS[((1 + abs(minlag)) - abs(lag)):(end - maxlag - abs(lag))]
        elseif lag == 0
            E[i, :] = TS[(1 + abs(minlag)):(end - maxlag)]
        end
    end
    embeddingdata = EmbeddingData{N, T}(
        ts,  # the dataseries
        ["" for i = 1:length(ts)], # empty labels by default
        ["" for i = 1:length(ts)], # empty descriptions by default
        EmbeddingPositions(in_which_pos), # the positions in which the dataseries appear
        EmbeddingLags(at_what_lags) # the embedding lag for each column
        )
    Embedding(Dataset(Array(transpose(E))), embeddingdata)
end

embed(A::SArray) = embed([A[:, i] for i in 1:size(S, 2)],
                        [i for i in 1:size(A, 2)],
                        [0 for i in 1:size(A, 2)])

embed(A::SArray, in_which_pos::Vector{Int}, at_what_lags::Vector{Int}) =
    embed([A[:, i] for i in 1:size(A, 2)],
    in_which_pos, at_what_lags)

####################################
# Pretty printing.
####################################
function summarise(r::EmbeddingData)
    n  = length(r.dataseries)
    _type = typeof(r)
    """$_type consisting of $n data series."""
end

function description(r::EmbeddingData)
    S = String[]
    lags_s = string.(r.at_what_lags)
    positions_s = join(string.(r.in_which_pos))
    indexed_s = join(string.(1:length(r.dataseries)), " ")
    if all(r.labels .== "")

        push!(S, " The time series are both unnamed")
    else
        lbls = join([" The time series have labels", r.labels], ", ")
        push!(S, lbls)
    end
    push!(S, ", are indexed $indexed_s, and the data series appear")
    push!(S, " as columns of the embedding in $positions_s at $lags_s.")
    S = join([summarise(r); S], "")
    return S
end

using Base.Iterators: flatten

function matstring(d::AbstractDataset{D, T}) where {D, T}
    N = length(d)
    if N > 36
        mat = zeros(eltype(d), 40, D)
        for (i, a) in enumerate(flatten((1:20, N-19:N)))
            mat[i, :] .= d[a]
        end
    else
        mat = Matrix(d)
    end
    s = sprint(io -> show(IOContext(io, :limit=>true), MIME"text/plain"(), mat))
    s = join(split(s, '\n')[2:end], '\n')
    return s
end

function summarise(r::AbstractEmbedding)
    n_dataseries = length(r.embeddingdata.dataseries)
    embedding_type = typeof(r)
    npts = length(r.points)
    summary = "$embedding_type with $npts points\n"
    return join([summary, matstring(r.points)], "")
end

Base.show(io::IO, r::EmbeddingData) = println(io, description(r))
Base.show(io::IO, r::Embedding) = println(io, summarise(r))

export
AbstractEmbedding,
Embedding,
EmbeddingData,
EmbeddingLags,
EmbeddingPositions,
embed,
label, labels,
lag, lags,
n,
at_what_lags,
in_which_pos,
which_series,
get_dataseries,
points,
npoints,
dimension,
minimum, maximum,
minima, maxima
