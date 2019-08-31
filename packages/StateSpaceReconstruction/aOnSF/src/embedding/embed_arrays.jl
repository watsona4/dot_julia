
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
    embeddingdata = EmbeddingData{dim, T}(
        ts,  # the dataseries
        ["" for i = 1:length(ts)], # empty labels by default
        ["" for i = 1:length(ts)], # empty descriptions by default
        EmbeddingPositions(in_which_pos), # the positions in which the dataseries appear
        EmbeddingLags(at_what_lags) # the embedding lag for each column
        )
    Embedding(E, embeddingdata)
end


"""
    embed(v::Vector{Vector{T}})

Returns an embedding of a vector of vectors, treating each
vector as a dynamical variable. Zero lag is used for all the
columns.
"""
function embed(v::Vector{Vector{T}}) where {T}
    D = length(v)
    embed(v, [i for i = 1:D], [0 for i in 1:D])
end

"""
    embed(A::AbstractArray{T, 2}) where T

Returns an embedding of an array, treating each
column as a dynamical variable. Zero lag is used
for all the columns.
"""
function embed(data::AbstractArray{T, 2}) where T

	if size(data, 1) > size(data, 2)
        #info("Treating each row of data as a point")
        dim = size(data, 2)
        which_pos = [i for i = 1:dim]
        which_lags = [0 for i in 1:dim]
        return embed([data[:, i] for i = 1:dim], which_pos, which_lags)
    else
        #info("Treating each column of data as a point")
        dim = size(data, 1)
        which_pos = [i for i = 1:dim]
        which_lags = [0 for i in 1:dim]
        return embed([data[i, :] for i = 1:dim], which_pos, which_lags)
	end
end

"""
    embed(data::AbstractArray{T, 2},
        in_which_pos::Vector{Int},
        at_what_lags::Vector{Int}) where T

Embedding of data represented by an array. Each
column of the array must correspond to one data series.
"""
function embed(data::AbstractArray{T, 2},
                in_which_pos::Vector{Int},
                at_what_lags::Vector{Int}) where T
    if size(data, 1) > size(data, 2)
        #info("Treating each row as a point")
        dim = size(data, 2)
        embed([data[:, i] for i = 1:dim], in_which_pos, at_what_lags)
    else
        #info("Treating each column of data as a point")
        dim = size(data, 1)
        embed([data[i, :] for i = 1:dim], in_which_pos, at_what_lags)
    end
end

export embed
