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

export NearNeighborRegression, optimize!, predict, predict_proba
import KernelMethods.CrossValidation: montecarlo, kfolds
using Statistics
using SimilaritySearch:
    Sequential, KnnResult, empty!, fit

mutable struct NearNeighborRegression{IndexType,DataType}
    dist::Function
    X::IndexType
    y::Vector{DataType}
    k::Int
    summarize::Function

    function NearNeighborRegression(dist::Function, X::AbstractVector{ItemType}, y::AbstractVector{DataType}; summarize=mean, k::Int=1) where {ItemType, DataType}
        index = fit(Sequential, X)
        new{typeof(index), DataType}(dist, index, y, k, summarize)
    end
end

function predict(nnc::NearNeighborRegression{IndexType,DataType}, vector) where {IndexType,DataType}
    [predict_one(nnc, item) for item in vector]
end

function predict_one(nnc::NearNeighborRegression{IndexType,DataType}, item) where {IndexType,DataType}
    res = KnnResult(nnc.k)
    search(nnc.X, nnc.dist, item, res)
    DataType[nnc.y[p.objID] for p in res] |> nnc.summarize
end

function _train_create_table_reg(dist::Function, train_X, train_y, test_X, k::Int)
    index = fit(Sequential, train_X)
    res = KnnResult(k)
    function f(x)
        empty!(res)  # this is thread unsafe
        search(index, dist, x, res)
        [train_y[p.objID] for p in res]
    end

    f.(test_X)
end

function _train_predict(nnc::NearNeighborRegression{IndexType,DataType}, table, test_X, k) where {IndexType,DataType}
    A = Vector{DataType}(undef, length(test_X))
    for i in 1:length(test_X)
        row = table[i]
        A[i] = nnc.summarize(row[1:k])
    end

    A
end

function gmean(X)
    prod(X)^(1/length(X))
end

function hmean(X)
    d = 0.0
    for x in X
        d += 1.0 / x
    end
    length(X) / d
end

function optimize!(nnr::NearNeighborRegression, scorefun::Function; summarize_list=[mean, median, gmean, hmean], runs=3, trainratio=0.5, testratio=0.5, folds=0, shufflefolds=true)
    mem = Dict{Tuple,Float64}()

    function f(train_X, train_y, test_X, test_y)
        _nnr = NearNeighborRegression(nnr.dist, train_X, train_y)
        kmax = sqrt(length(train_y)) |> round |> Int
        table = _train_create_table_reg(nnr.dist, train_X, train_y, test_X, kmax)
        k = 2
        while k <= kmax
            _nnr.k = k - 1
            for summarize in summarize_list
                _nnr.summarize = summarize
                pred_y = _train_predict(_nnr, table, test_X, _nnr.k)
                score = scorefun(test_y, pred_y)
                key = (k - 1, summarize)
                mem[key] = get(mem, key, 0.0) + score
            end
            k += k
        end
        0
    end

    if folds > 1
        kfolds(f, nnr.X.db, nnr.y, folds=folds, shuffle=shufflefolds)
        bestlist = [(score/folds, conf) for (conf, score) in mem]
    else
        montecarlo(f, nnr.X.db, nnr.y, runs=runs, trainratio=trainratio, testratio=testratio)
        bestlist = [(score/runs, conf) for (conf, score) in mem]
    end

    sort!(bestlist, by=x -> (-x[1], x[2][1]))
    best = bestlist[1]
    nnr.k = best[2][1]
    nnr.summarize = best[2][2]

    bestlist
end