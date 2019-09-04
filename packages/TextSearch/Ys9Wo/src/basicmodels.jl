export VectorModel, fit, vectorize, TfidfModel, TfModel, IdfModel, FreqModel

"""
    abstract type Model

An abstract type that represents a weighting model
"""
abstract type Model end

"""
    mutable struct VectorModel

Models a text through a vector space
"""
mutable struct VectorModel <: Model
    config::TextConfig
    tokens::BOW
    maxfreq::Int
    n::Int
end

"""
    fit(::Type{VectorModel}, config::TextConfig, corpus::AbstractVector)

Trains a vector model using the text preprocessing configuration `config` and the input corpus. 
"""
function fit(::Type{VectorModel}, config::TextConfig, corpus::AbstractVector)
    voc = BOW()
    n = 0
    maxfreq = 0.0
    println(stderr, "fitting VectorModel with $(length(corpus)) items")

    for data in corpus
        n += 1
        _, maxfreq = compute_bow(config, data, voc)
        n % 1000 == 0 && print(stderr, "x")
        n % 100000 == 0 && println(stderr, " $(n/length(corpus))")
    end

    println(stderr, "finished VectorModel: $n processed items")
    VectorModel(config, voc, Int(maxfreq), n)
end

"""
    prune(model::VectorModel, minfreq, rank=1.0)

Cuts the vocabulary by frequency using lower and higher filter;
All tokens with frequency below `freq` are ignored; also, all tokens
with rank lesser than `rank` (top frequencies) are ignored. 
"""
function prune(model::VectorModel, freq::Int, rank::Int)
    # _weight(IdfModel, )
    W = [token => f for (token, f) in model.tokens if f >= freq]
    sort!(W, by=x->x[2])
    M = BOW()
    for i in 1:length(W)-rank+1
        w = W[i]
        M[w[1]] = w[2]
    end
    VectorModel(model.config, M, model.maxfreq, model.n)
end

"""
    update!(a::VectorModel, b::VectorModel)

Updates `a` with `b` inplace; returns `a`.
"""
function update!(a::VectorModel, b::VectorModel)
    i = 0
    for (k, freq1) in b.tokens
        i += 1
        freq2 = get(a, k, 0.0)
        if freq1 == 0.0
            a[k] = freq1
        else
            a[k] = freq1 + freq2
        end
    end

    a.maxfreq = max(a.maxfreq, b.maxfreq)
    a.n += b.n
    a
end

abstract type TfidfModel end
abstract type TfModel end
abstract type IdfModel end
abstract type FreqModel end

"""
    vectorize(model::VectorModel, weighting::Type, data, modify_bow!::Function=identity)::Dict{Symbol, Float64}

Computes `data`'s weighted bag of words using the given model and weighting scheme.
It takes a function `modify_bow!` to modify the bag
before applying the weighting scheme; `modify_bow!` defaults to `identity`.
"""
function vectorize(model::VectorModel, weighting::Type, data, modify_bow!::Function=identity)::BOW
    W = BOW()
    bag, maxfreq = compute_bow(model.config, data)
    bag = modify_bow!(bag)
    for (token, freq) in bag
        global_freq = get(model.tokens, token, 0.0)
        if global_freq > 0.0
            W[token] = _weight(weighting, freq, maxfreq, model.n, global_freq)
        end
    end
  
    W
end

vectorize(model::VectorModel, data, modify_bow!::Function=identity) = vectorize(model, TfidfModel, data, modify_bow!)

function broadcastable(model::VectorModel)
    (model,)
end

"""
    _weight(::Type{T}, freq::Integer, maxfreq::Integer, n::Integer, global_freq::Integer)::Float64

Computes a weight for the given stats using scheme T
"""
function _weight(::Type{TfidfModel}, freq::Real, maxfreq::Real, n::Real, global_freq::Real)::Float64
    (freq / maxfreq) * log(2, 1 + n / global_freq)
end

function _weight(::Type{TfModel}, freq::Real, maxfreq::Real, n::Real, global_freq::Real)::Float64
    freq / maxfreq
end

function _weight(::Type{IdfModel}, freq::Real, maxfreq::Real, n::Real, global_freq::Real)::Float64
    log(2, n / global_freq)
end

function _weight(::Type{FreqModel}, freq::Real, maxfreq::Real, n::Real, global_freq::Real)::Float64
    freq
end
