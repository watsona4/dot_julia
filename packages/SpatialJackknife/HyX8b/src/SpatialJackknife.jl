module SpatialJackknife


using Statistics, LinearAlgebra
using NearestNeighbors, Distances


export jackknife, get_subvols


"""
This function gets dimensions of a given data array and returns an error if
they are not appropriate or consistent with the dimension of optional randoms.
"""
function get_dims(data::Array{Float64, 2},
                  randmask::Array{Float64, 2} = ones(0, 0))::Tuple{Int, Int}

    ndat, ndims = size(data)

    if ndat < ndims
        throw(ArgumentError("data array must have shape (ndat, ndims)"))
    end

    if !isempty(randmask)
        if ndims != size(randmask)[2]
            throw(ArgumentError("data array and mask array must have same number of dimensions"))
        end
    end

    ndat, ndims
end


"""
This function takes a dataset and returns an array of subvolume indices for
each datapoint. In this case, it takes a set of random mask points for
dividing arbitrary volumes. It computes the quantiles of the mask and then
finds the closest mask point to each data point to determine the subvolume
the data point belongs in.

The function expects a data array with shape (ndat, ndims) for Ndat samples in
ndims dimensions. The mask array should have shape (nmask, ndims) and then
there is an integere side_divs which specifies the number of times each
dimension is divided up to make side_divs^ndims subvolumes.
"""
function get_subvols(data::Array{Float64, 2},
                     randmask::Array{Float64, 2},
                     side_divs::Int,
                     metric::Metric = Euclidean())::Array{Int, 1}

    ndat, ndims = get_dims(data, randmask)
    nmask = size(randmask)[1]

    # now to figure out which subvolume each of the mask points is in by
    # getting the quantiles in each dimension
    maskvols = ones(Int, nmask)
    volnums = [1]  # start off with all points in the same volume
    for i in 1:ndims

        # creates a set of numbers to assign volumes for the ith dimension
        nuvolnums = [(a - 1) * side_divs^(ndims - i) for a in 1:(side_divs^i)] .+ 1

        for (j, volnum) in enumerate(volnums)
            dimmask = findall(maskvols .== volnum)
            dimquants = quantile(randmask[dimmask, i],
                                 range(0, stop = 1, length = side_divs + 1))
            dimquants[end] += 1

            for k in 2:side_divs
                submask = findall(dimquants[k] .<= randmask[dimmask, i] .< dimquants[k + 1])
                maskvols[dimmask[submask]] .= nuvolnums[side_divs * (j - 1) + k]
            end
        end

        volnums = nuvolnums
    end

    # and find the closest random to each data point to find the subvolume
    balltree = BallTree(collect(randmask'), metric)
    nninds, dists = knn(balltree, collect(data'), 1)

    subvols = maskvols[[n[1] for n in nninds]]
    subvols
end


"""
As with the other method for get_subvols, this function computes the subvolume
indices for given samples. It assumes a constant density throughout the
volume. The method computes the subvolumes based on a set of extrema for
sample values in each dimension and a number of volumes to divide the sample
on per side. If a single set of extrema are given, the assumption is that they are the same in each dimension. Alternatively, it can take a set of volume
edges in each dimension.
"""
function get_subvols(data::Array{Float64, 2};
                     side_divs::Int = 3,
                     edges::Array{Array{Float64, 1}, 1} = Array{Array{Float64, 1}, 1}(undef, 0))::Array{Int, 1}

    ndat, ndims = get_dims(data)

    if length(edges) == 1
        edges = [edges[1] for a in 1:ndims]
    elseif length(edges) != ndims
        throw(ArgumentError("edges argument must have either one array or as many arrays as dimensions in the data"))
    end

    if !all(length.(edges) .== length(edges[1]))
        throw(ArgumentError("expect the edges arrays to all have the same length since volume is a cube"))
    end

    if length(edges[1]) == 2
        edges = [collect(range(ed[1], stop = ed[2],
                               length = side_divs + 1)) for ed in edges]
    end

    # now to use the edges to assign subvolume indices
    subvols = ones(Int, ndat)
    diminds = ones(Int, ndims)
    dimfacs = [side_divs^(ndims - a) for a in 1:ndims]
    for i in 1:ndat
        for j in 1:ndims
            diminds[j] = maximum(findall(data[i, j] .>= edges[j]))
        end
        subvols[i] = sum(dimfacs .* (diminds .- 1)) + 1
    end

    subvols
end


"""
This function computes the jackknife mean and variance over the observations
computed from the data with obsfunc. They are computed by repeatedly applying
obsfunc to the data with one of the subvolumes removed. It therefore assumes
that obsfunc has normalised the observable for that remaining volume. The
function obsfunc must be callable with the form

obsfunc(data::Array{Float64, 2}, args...)

for optional args tuple and the value returned by obsfunc must be in the form of an array of floats. If any of the returned values are NaNs, an error will be
raised. By default, the covariance matrix is computed for observables in more
than one dimension, but setting covar to false will result in only the diagonal
variances being returned.
"""
function jackknife(obsfunc::Function,
                   data::Array{Float64, 2},
                   subvolinds::Array{Int, 1},
                   args::Tuple = ();
                   covar::Bool = true)::Tuple

    volset = BitSet(subvolinds)
    nvols = length(volset)
    meanfac = 1 / nvols
    varfac = (nvols - 1) / nvols

    # get the observables for the data with each volume left out
    local ivals::Array{Array{Float64, 1}, 1}
    ivals = [obsfunc(data[findall(subvolinds .!= vol), :],
                     args...) for vol in volset]
    meanvals = sum(ivals) .* meanfac

    if any(isnan.(meanvals))
        throw(ErrorException("nans returned by obsfunc, perhaps the data is too sparse for the selected size/number of subvolumes"))
    end

    ndims = length(meanvals)

    # now to get the (co)variance
    covarmat = zeros(ndims, ndims)
    for i in 1:ndims
        for j in i:ndims
            if !covar && i != j
                continue
            end

            covarmat[i, j] = varfac * sum([(ivals[k][i] - meanvals[i]) *
                                           (ivals[k][j] - meanvals[j]) for k in 1:nvols])
            covarmat[j, i] = covarmat[i, j]
        end
    end

    if ndims == 1
        return meanvals, covarmat[1, 1]
    elseif !covar
        return meanvals, diag(covarmat)
    else
        return meanvals, covarmat
    end
end


end
