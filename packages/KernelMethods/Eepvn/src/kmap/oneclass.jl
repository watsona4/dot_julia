using StatsBase: countmap

export OneClassClassifier, regions, centroid, fit, predict

mutable struct OneClassClassifier{T}
    centers::Vector{T}
    freqs::Vector{Int}
    n::Int
    epsilon::Float64
end

function fit(::Type{OneClassClassifier}, dist::Function, X::AbstractVector{T}, m::Int; centroids=true) where T
    Q = fftclustering(dist, X, m)
    C = X[Q.irefs]
    P = Dict(Q.irefs[i] => i for i in eachindex(Q.irefs))
    freqs = zeros(Int, length(Q.irefs))
    for nn in Q.NN
        freqs[P[first(nn).objID]] += 1
    end

    if centroids
        CC = centroid_correction(dist, X, C)
        OneClassClassifier(CC, freqs, length(X), Q.dmax) 
    else
        OneClassClassifier(C, freqs, length(X), Q.dmax)
    end
    
end

function regions(dist::Function, X, refs::Index)
    I = KMap.invindex(dist, X, refs, k=1)
    (freqs=[length(lst) for lst in I], regions=I)
end

function regions(dist::Function, X, refs)
    regions(dist, X, fit(Sequential, refs))
end

function centroid(D)
    sum(D) ./ length(D)
end

function centroid_correction(dist::Function, X, C)
    [centroid(X[lst]) for lst in regions(dist, X, C).regions if length(lst) > 0]
end

function predict(occ::OneClassClassifier{T}, dist::Function, q::T) where T
    seq = fit(Sequential, occ.centers)
    res = search(seq, dist, q, KnnResult(1))
    #1.0 - first(res).dist  / occ.epsilon
    (similarity=max(0.0, 1.0 - first(res).dist  / occ.epsilon), freq=occ.freqs[first(res).objID])
    #occ.freqs[first(res).objID] / occ.n
end