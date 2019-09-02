# Copyright 2017,2018 Eric S. Tellez
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import SimilaritySearch: optimize!
export NaiveBayesClassifier, NaiveBayesKernel, kernel_prob, predict, predict_proba, optimize!

abstract type NaiveBayesKernel end

mutable struct NaiveBayesClassifier{ItemType,LabelType}
    kernel::NaiveBayesKernel
    probs::Vector{Float64}
    le::LabelEncoder{LabelType}
end

include("nbgaussian.jl")
include("nbmultinomial.jl")

function NaiveBayesClassifier(X::AbstractVector{ItemType}, y::AbstractVector{LabelType}; kernel=GaussianKernel) where {ItemType,LabelType}
    le = LabelEncoder(y)
    # y_ = [transform(le, l) for l in y]
    y_ = transform.(le, y)
    probs = Float64[freq/length(y) for freq in le.freqs]
    kernel_ = kernel(X, y_, length(le.labels))
    NaiveBayesClassifier{ItemType,LabelType}(kernel_, probs, le)
end

function predict(nbc::NaiveBayesClassifier{ItemType,LabelType}, vector)::Vector{LabelType} where {ItemType,LabelType}
    y = Vector{LabelType}(undef, length(vector))
    for i in 1:length(vector)
        y[i] = predict_one(nbc, vector[i])
    end

    y
end

function predict_one_proba(nbc::NaiveBayesClassifier{ItemType,LabelType}, x) where {ItemType,LabelType}
    w = kernel_prob(nbc, nbc.kernel, x)
    ws = sum(w)
    @inbounds for i in 1:length(w)
        w[i] /= ws
    end
    w
end

function predict_one(nbc::NaiveBayesClassifier{ItemType,LabelType}, x) where {ItemType,LabelType}
    p, i = findmax(kernel_prob(nbc, nbc.kernel, x))
    inverse_transform(nbc.le, i)
end

function optimize!(nbc::NaiveBayesClassifier{ItemType,LabelType}, X::AbstractVector{ItemType}, y::AbstractVector{LabelType}, scorefun::Function; runs=3, trainratio=0.5, testratio=0.5, folds=0, shufflefolds=true) where {ItemType,LabelType}
    @info "optimizing nbc $(typeof(nbc))"
    # y::Vector{Int} = transform.(nbc.le, y)
    mem = Dict{Any,Float64}()
    function f(train_X, train_y, test_X, test_y)
        tmp = NaiveBayesClassifier(train_X, train_y, kernel=MultinomialKernel)
        for smoothing in [0.0, 0.1, 0.3, 1.0]
            tmp.kernel.smoothing = smoothing
            pred_y = predict(tmp, test_X)
            score = scorefun(test_y, pred_y)
            mem[(MultinomialKernel, smoothing)] = get(mem, (MultinomialKernel, smoothing), 0.0) + score
        end

        tmp.kernel = GaussianKernel(train_X, transform.(tmp.le, train_y), length(tmp.le.labels))
        pred_y = predict(tmp, test_X)
        score = scorefun(test_y, pred_y)
        mem[(GaussianKernel, -1)] = get(mem, (GaussianKernel, -1), 0.0) + score
        0
    end

    if folds > 1
        kfolds(f, X, y, folds=folds, shuffle=shufflefolds)
        bestlist = [(score/folds, conf) for (conf, score) in mem]
    else
        montecarlo(f, X, y, runs=runs, trainratio=trainratio, testratio=testratio)
        bestlist = [(score/runs, conf) for (conf, score) in mem]
    end

    sort!(bestlist, by=x -> (-x[1], x[2][2]))
    best = bestlist[1][2]
    if best[1] == GaussianKernel
        nbc.kernel = GaussianKernel(X, transform.(nbc.le, y), length(nbc.le.labels))
    else
        nbc.kernel = MultinomialKernel(X, transform.(nbc.le, y), length(nbc.le.labels), smoothing=best[2])
    end

    bestlist
end
