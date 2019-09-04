export Rocchio, RocchioBagging, fit, predict, transform
import SimilaritySearch: KnnResult
using StatsBase: countmap

mutable struct Rocchio
    protos::Vector{BOW}  # prototypes
    pops::Vector{Int} # population per class
end

const RocchioBagging = Vector{Rocchio}

function fit(::Type{Rocchio}, X::AbstractVector{BOW}, y::AbstractVector{Int}; nclasses=0)
    if nclasses == 0
        nclasses = unique(y) |> length
    end

    prototypes = [BOW() for i in 1:nclasses]
    populations = zeros(Int, nclasses)
    println(stderr, "fitting Rocchio classifier with $(length(X)) items; and $nclasses classes")
    for i in 1:length(X)
        i % 1000 == 0 && print(stderr, "*")
        i % 100000 == 0 && println(stderr, " adv: $(i / length(X))")
        c = y[i]
        add!(prototypes[c], X[i])
        populations[c] += 1
    end

    for bow in prototypes
        normalize!(bow)
    end

    Rocchio(prototypes, populations)
end

function predict(rocchio::Rocchio, x::BOW)
    res = KnnResult(1)
    for i in 1:length(rocchio.protos)
        d = cosine_distance(rocchio.protos[i], x)
        push!(res, i, d)
    end

    first(res).objID
end

function transform(rocchio::Rocchio, x::BOW)
    [dot(rocchio.protos[i], x) for i in 1:length(rocchio.protos)]
end

function broadcastable(rocchio::Rocchio)
    (rocchio,)
end

function fit(::Type{RocchioBagging}, X::AbstractVector{BOW}, y::AbstractVector{Int}, nrocchios=5; nclasses=0)::RocchioBagging
    if nclasses == 0
        nclasses = unique(y) |> length
    end

    s = ceil(Int, length(X) / 2)
    L = RocchioBagging()
    for i in 1:nrocchios
        I = rand(1:length(X), s)
        rocchio = fit(Rocchio, X[I], y[I], nclasses=nclasses)
        push!(L, rocchio)
    end

    L
end

function predict(rocchio::RocchioBagging, x::BOW)
    P = [predict(r, x) for r in rocchio] |> countmap |> collect
    sort!(P, by=x->x[end])
    P[end][1]
end

function transform(rocchio::RocchioBagging, x::BOW)
    sum(transform(r, x) for r in rocchio) |> normalize!
end

function broadcastable(rocchio::RocchioBagging)
    (rocchio,)
end
