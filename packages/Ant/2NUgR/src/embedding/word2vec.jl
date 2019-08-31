#!/usr/bin/env julia
# del2z <delta.z@aliyun.com>

#module Word2Vec

using Flux
using Flux: glorot_normal, ADAM, OneHotMatrix, OneHotVector, onehot, onehotbatch, onecold, logitbinarycrossentropy, throttle
using JSON
using DataStructures
using StatsBase

const config = JSON.parsefile(joinpath(@__DIR__, "word2vec.json"))

include("prepro.jl")

corpus = segment!(loaddata("corpus.txt"))
wordfreq = genvocab(corpus, 1)

index2word = ["<UNK>"; "</s>"; collect(keys(wordfreq))]
vocabsize = length(index2word)
word2index = OrderedDict(zip(index2word, 1:vocabsize))

## model graph
embedsize = config["model"]["embed_size"]
W̃_in = param(glorot_normal(embedsize, vocabsize))
W̃_out = param(glorot_normal(vocabsize, embedsize))
b̃_out = param(zeros(vocabsize))

function dataset end
function model end
function loss end

window = config["model"]["window"]
@assert isodd(window)
negscale = config["model"]["neg_scale"]
if config["method"] == "cbow"
    dataset(corpus::Vector{Vector{String}}) = begin
        Xs = Vector{OneHotMatrix}()
        Ys = Vector{OneHotVector}()
        for seq in corpus
            size(seq, 1) >= window || continue
            for k in 1:(size(seq, 1) - window + 1)
                chunk = seq[k:(k - 1 + window)]
                in(chunk[(window + 1) ÷ 2], index2word) || continue
                push!(Xs, onehotbatch([chunk[i] for i in filter(x -> x != (window + 1) ÷ 2, 1:window)],
                                      index2word, "<UNK>"))
                push!(Ys, onehot(chunk[(window + 1) ÷ 2], index2word, "<UNK>"))
            end
        end
        Xs, Ys
    end

    model(x::OneHotMatrix) = begin
        W̃_out * sum(W̃_in * x, dims = 2) + b̃_out
    end

    loss(x::OneHotMatrix, y::OneHotVector) = begin
        posid = onecold(y)
        negids = sample(setdiff(1:size(y, 1), [posid]), negscale, replace = false, ordered = true)
        ŷ = model(x)
        ℒ = logitbinarycrossentropy(ŷ[posid], 1) + sum(logitbinarycrossentropy.(ŷ[negids], zeros(length(negids))))
        ℒ / (1 + length(negids))
    end
else
    dataset(corpus::Vector{Vector{String}}) = begin
        Xs = Vector{OneHotVector}()
        Ys = Vector{OneHotMatrix}()
        for seq in corpus
            size(seq, 1) >= window || continue
            for k in 1:(size(seq, 1) - window + 1)
                chunk = seq[k:(k - 1 + window)]
                in(chunk[(window + 1) ÷ 2], index2word) || continue
                push!(Xs, onehot(chunk[(window + 1) ÷ 2], index2word, "<UNK>"))
                push!(Ys, onehotbatch([chunk[i] for i in filter(x -> x != (window + 1) ÷ 2, 1:window)],
                                      index2word, "<UNK>"))
            end
        end
        Xs, Ys
    end

    model(x::OneHotVector) = begin
        W̃_out * W̃_in * x + b̃_out
    end

    loss(x::OneHotVector, y::OneHotMatrix) = begin
        posids = onecold(y)
        negids = sample(setdiff(1:size(y, 1), posids), negscale * length(posids), replace = false, ordered = true)
        ŷ = model(x)
        ℒ = sum(logitbinarycrossentropy.(ŷ[posids], ones(length(posids)))) + sum(logitbinarycrossentropy.(ŷ[negids], zeros(length(negids))))
        ℒ / (length(posids) + length(negids))
    end
end

## training
Xs, Ys = dataset(corpus)
@info size(Xs), size(Ys)
opt = ADAM(0.002)

for ep in 1:config["model"]["epochs"]
    Flux.train!(loss, params(W̃_in, W̃_out, b̃_out), zip(Xs, Ys), opt)
    @info sum(map(p -> loss(p...), zip(Xs, Ys)))
end

## testing

#end
