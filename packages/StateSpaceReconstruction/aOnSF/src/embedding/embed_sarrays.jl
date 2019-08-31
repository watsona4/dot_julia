########################################
# SArrays and SVectors
########################################
function embed(ts::Vector{SArray{Size,T,N,L}},
        in_which_pos::Vector{Int},
        at_what_lags::Vector{Int}) where {Size, T, N, L}
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
    Embedding(Array(E), embeddingdata)
end

"""
    embed(data::SArray) where T

Construct an embedding from data series gathered in a `SArray`.
"""
function embed(data::SArray)
	if size(data, 1) > size(data, 2)
		#info("Treating each row as a point")
		dim = size(data, 2)
        which_pos = [i for i = 1:dim]
        which_lags = [0 for i in 1:dim]
		embed([data[:, i] for i = 1:dim], which_pos, which_lags)
	else
		#info("Treating each column of data as a point")
		dim = size(data, 1)
        which_pos = [i for i = 1:dim]
        which_lags = [0 for i in 1:dim]
		embed([data[i, :] for i = 1:dim], which_pos, which_lags)
	end
end


"""
    embed(data::SArray) where T

Construct an embedding from data series gathered in a `SArray`, specifying the
dimensionality, which variables in the embedding are represented by which
variables in the `data` array, and what the embedding lags should be.
"""
function embed(data::SArray, which_pos::Vector{Int}, which_lags::Vector{Int})
    if size(data, 1) > size(data, 2)
		#info("Treating each row as a point")
		dim = size(data, 2)
		embed([data[:, i] for i = 1:dim], which_pos, which_lags)
	else
		#info("Treating each column of data as a point")
		dim = size(data, 1)
		embed([data[i, :] for i = 1:dim], which_pos, which_lags)
	end
end

export embed
