using SimilaritySearch
export fftraversal, fftclustering

function _ignore3(a, b, c)
end

"""
Selects a number of farthest points in `X`, using a farthest first traversal

- The callback function is called on each selected far point as `callback(centerID, dmax)` where `dmax` is the distance to the nearest previous reported center (the first is reported with typemax)
- The selected objects are far under the `dist` distance function with signature (T, T) -> Float64
- The number of points is determined by the stop criterion function with signature (Float64[], T[]) -> Bool
    - The first argument corresponds to the list of known distances (far objects)
    - The second argument corresponds to the database
- Check `criterions.jl` for basic implementations of stop criterions
- The callbackdist function is called on each distance evaluation between pivots and items in the dataset
    `callbackdist(index-pivot, index-item, distance)`
"""
function fftraversal(callback::Function, dist::Function, X::AbstractVector{T}, stop, callbackdist=_ignore3) where {T}
    N = length(X)
    D = Vector{Float64}(undef, N)
    dmaxlist = Float64[]
    dset = [typemax(Float64) for i in 1:N]
    imax::Int = rand(1:N)
    dmax::Float64 = typemax(Float64)
    if N == 0
        return
    end

    k::Int = 0
    
    @inbounds while k <= N
        k += 1
        pivot = X[imax]
        push!(dmaxlist, dmax)
        callback(imax, dmax)
        println(stderr, "computing fartest point $k, dmax: $dmax, imax: $imax, stop: $stop")
        dmax = 0.0
        ipivot = imax
        imax = 0

        D .= 0.0
        Threads.@threads for i in 1:N
            D[i] = dist(X[i], pivot)
        end

        for i in 1:N
            # d = dist(X[i], pivot)
            d = D[i]
            callbackdist(i, ipivot, d)

            if d < dset[i]
                dset[i] = d
            end

            if dset[i] > dmax
                dmax = dset[i]
                imax = i
            end
        end

        if dmax == 0 || stop(dmaxlist, X)
            break
        end
    end
end

"""
    fftclustering(dist::Function, X::Vector{T}, numcenters::Int, k::Int) where T

Clustering algorithm based on Farthest First Traversal (an efficient solution for the K-centers problem).
- `dist` distance function
- `X` contains the objects to be clustered
- `numcenters` number of centers to be computed
- `k` number of nearest references per object (k=1 makes a partition)

Returns a named tuple ``(NN, irefs, dmax)``.

- `NN` contains the ``k`` nearest references for each object in ``X``.
- `irefs` contains the list of centers (indexes to ``X``)
- `dmax` smallest distance among centers

"""
function fftclustering(dist::Function, X::Vector{T}, numcenters::Int; k::Int=1) where T
    # refs = Vector{Float64}[]
    irefs = Int[]
    NN = [KnnResult(k) for i in 1:length(X)]
    dmax = 0.0

    function callback(c, _dmax)
        push!(irefs, c)
        dmax = _dmax
    end

    function capturenn(i, refID, d)
        push!(NN[i], refID, d)
    end

    fftraversal(callback, dist, X, size_criterion(numcenters), capturenn)
    return (NN=NN, irefs=irefs, dmax=dmax)
end