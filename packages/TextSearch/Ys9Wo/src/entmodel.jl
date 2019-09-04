export EntModel

mutable struct EntModel <: Model
    tokens::BOW
    config::TextConfig
end

function smooth_factor(dist::AbstractVector)::Float64
    s = sum(dist)
    s < length(dist) ? 1.0 : 0.0
end

"""
    fit(::Type{EntModel}, model::DistModel, smooth::Function=smooth_factor; lower=0.001)


Fits an EntModel using the already fitted DistModel; the `smooth` function is called to compute the smoothing factor
for a given histogram. It accepts only symbols with a final weight higher or equal than `lower`.
"""
function fit(::Type{EntModel}, model::DistModel, smooth::Function=smooth_factor; lower=0.001)
    tokens = BOW()
    nclasses = length(model.sizes)
    maxent = log2(nclasses)

    @inbounds for (token, dist) in model.tokens
        b = smooth(dist)
        e = 0.0
        pop = b * nclasses + sum(dist)

        for j in 1:nclasses
            pj = (dist[j] + b) / pop

            if pj > 0.0
                e -= pj * log2(pj)
            end
        end
        e = 1.0 - e / maxent
        if e >= lower
            tokens[token] = e
        end
    end

    EntModel(tokens, model.config)
end

function fit(::Type{EntModel}, config::TextConfig, corpus, y; nclasses=0, norm_by=minimum, smooth=smooth_factor, lower=0.001)
    dmodel = fit(DistModel, config, corpus, y, nclasses=nclasses, norm_by=minimum)
    fit(EntModel, dmodel, smooth, lower=lower)
end

"""
    prune(model::EntModel, lower)

Prunes the model accepting only those symbols with a weight higher than `lower`

"""
function prune(model::EntModel, lower)
    tokens = BOW()
    for (t, ent) in model.tokens
        if ent >= lower
            tokens[t] = ent
        end
    end
    
    EntModel(tokens, model.config)
end

abstract type EntTfModel end
abstract type EntTpModel end

"""
    vectorize(model::EntModel, data, modify_bow!::Function=identity)::BOW
    vectorize(model::EntModel, ::Type, data, modify_bow!::Function=identity)::BOW

Computes a weighted bow for a given `data`
"""
function vectorize(model::EntModel, scheme::Type{T}, data, modify_bow!::Function=identity)::BOW where T <: Union{EntTfModel,EntTpModel,EntModel}
    bow, maxfreq = compute_bow(model.config, data)
    len = 0
    for v in values(bow)
        len += v
    end
    bow = modify_bow!(bow)
    for (token, freq) in bow
        w = get(model.tokens, token, 0.0)
        w = _weight(scheme, w, freq,  len)
        if w > 0.0
            bow[token] = w
        else
            delete!(bow, token)
        end
    end

    bow    
end

vectorize(model::EntModel, data, modify_bow!::Function=identity) = vectorize(model, EntTpModel, data, modify_bow!)

_weight(::Type{EntTpModel}, ent, freq, n) = ent * freq / n
_weight(::Type{EntTfModel}, ent, freq, n) = ent * freq
_weight(::Type{EntModel}, ent, freq, n) = ent

function broadcastable(model::EntModel)
    (model,)
end
