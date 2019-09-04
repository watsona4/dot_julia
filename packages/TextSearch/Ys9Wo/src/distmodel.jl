export DistModel, feed!, fix!

mutable struct DistModel <: Model
    tokens::Dict{Symbol, Vector{Int}}
    config::TextConfig
    sizes::Vector{Int}
end

const EMPTY_TOKEN_DIST = Int[]

function fit(::Type{DistModel}, config::TextConfig, corpus, y; nclasses=0, norm_by=minimum)
    if nclasses == 0
        nclasses = unique(y) |> length
    end
    
    model = DistModel(BOW(), config, zeros(Int, nclasses))
    feed!(model, corpus, y)
    model
end

function feed!(model::DistModel, corpus, y)
    config = model.config
    nclasses = length(model.sizes)
    n = 0
    println(stderr, "feeding DistModel with $(length(corpus)) items, classes: $(nclasses)")
    for (klass, text) in zip(y, corpus)
        for token in tokenize(config, text)
            token_dist = get(model.tokens, token, EMPTY_TOKEN_DIST)
            if length(token_dist) == 0
                token_dist = zeros(Float64, nclasses)
                model.tokens[token] = token_dist
            end
            token_dist[klass] += 1
        end
        model.sizes[klass] += 1
        n += 1
        n % 1000 == 0 && print(stderr, "*")
        n % 100000 == 0 && println(stderr, " dist: $(model.sizes), adv: $n")
    end
    println(stderr, "finished DistModel: $n processed items")

    model
end

function normalize!(model::DistModel, by=minimum)
    nclasses = length(model.sizes)
    val = by(model.sizes)

    for (token, hist) in model.tokens
        for i in 1:nclasses
            hist[i] *= val / model.sizes[i]
        end
    end
end

function fix!(model::DistModel)
    nclasses = length(model.sizes)
    nterms = length(model.tokens)

    for (token, dist) in model.tokens
        s = sum(dist)
        for i in 1:nclasses
            dist[i] /= s
        end

    end

    model
end

function fit(model::DistModel, corpus, y; norm_by=nothing)
    feed!(model, corpus, y)
    if norm_by != nothing
        normalize!(model, norm_by)
    end
    fix!(model)
end