#!/usr/bin/env julia
# del2z <delta.z@aliyun.com>

using StatsBase
using DataStructures

" Load raw corpus into `Vector{String}` "
function loaddata(fname::AbstractString)
    corpus = Vector{String}()
    open(fname, "r") do fin
        for line in eachline(fin)
            length(line) > 10 && push!(corpus, strip(line))
        end
    end
    corpus
end

" Segment words in corpus "
function segment!(corpus::Vector{<:AbstractString})
    newcorp = Vector{Vector{String}}()
    for k in 1:length(corpus)
        push!(newcorp, string.(collect(corpus[k])))
    end
    newcorp
end

" Generate vocabulary from corpus "
function genvocab(corpus::Vector{Vector{String}}, mincount::Integer = 0)
    wordcount = Dict{String,Int64}()
    for k in 1:length(corpus)
        addcounts!(wordcount, corpus[k])
    end
    totalcount = (mincount <= 0) ? sum(values(wordcount)) :
                 sum(values(filter!(kv -> kv.second >= mincount, wordcount)))
    wordfreq = OrderedDict(map(kv -> (kv.first, kv.second / totalcount), collect(wordcount)))
    wordfreq
end
