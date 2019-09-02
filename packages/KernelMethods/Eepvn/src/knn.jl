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


using SimilaritySearch:
    Sequential, KnnResult
import SimilaritySearch: optimize!
import KernelMethods.CrossValidation: montecarlo, kfolds
export NearNeighborClassifier, optimize!, predict, predict_proba

mutable struct NearNeighborClassifier{IndexType,LabelType}
    dist::Function
    X::IndexType
    y::Vector{Int}
    k::Int
    le::LabelEncoder{LabelType}
    weight

    function NearNeighborClassifier(dist::Function, X::AbstractVector{ItemType}, y::AbstractVector{LabelType}, k::Int=1, weight=:uniform, create_index=nothing) where {ItemType, LabelType}
        le = LabelEncoder(y)
        y_ = [transform(le, l) for l in y]
       
        if create_index == nothing
            index = fit(Sequential, X)
        else
            index = create_index(X)
        end

        new{typeof(index), LabelType}(dist, index, y_, k, le, weight)
    end
end

function predict(nnc::NearNeighborClassifier{IndexType,LabelType}, vector) where {IndexType,LabelType}
    [predict_one(nnc, item) for item in vector]
end

function predict_proba(nnc::NearNeighborClassifier{IndexType,LabelType}, vector::AbstractVector; smoothing=0.0) where {IndexType,LabelType}
    [predict_one_proba(nnc, item, smoothing=smoothing) for item in vector]
end

function _predict_one(nnc::NearNeighborClassifier{IndexType,LabelType}, item) where {IndexType,LabelType}
    res = KnnResult(nnc.k)
    search(nnc.X, nnc.dist, item, res)
    w = zeros(Float64, length(nnc.le.labels))
    if nnc.weight == :uniform
        for p in res
            l = nnc.y[p.objID]
            w[l] += 1.0
        end
    elseif nnc.weight == :distance
        for p in res
            l = nnc.y[p.objID]
            w[l] += 1.0 / (1.0 + p.dist)
        end
    else
        throw(ArgumentError("Unknown weighting scheme $(nnc.weight)"))
    end

    w
end

function predict_one(nnc::NearNeighborClassifier{IndexType,LabelType}, item) where {IndexType,LabelType}
    score, i = findmax(_predict_one(nnc, item))
    inverse_transform(nnc.le, i)
end

function predict_one_proba(nnc::NearNeighborClassifier{IndexType,LabelType}, item; smoothing=0.0) where {IndexType,LabelType}
    w = _predict_one(nnc, item)
    t = sum(w)

    s = t * smoothing
    ss = s * length(w)

    for i in 1:length(w)
        w[i] = (w[i] + s) / (t + ss)  # overriding previous w
    end

    w
end

function _train_create_table(dist::Function, train_X, train_y, test_X, k::Int)
    index = fit(Sequential, train_X)
    tab = Vector{Vector{Tuple{Int,Float64}}}(undef, length(test_X))

    for i in 1:length(test_X)
        res = search(index, dist, test_X[i], KnnResult(k))
        tab[i] = [(train_y[p.objID], p.dist) for p in res]
    end

    tab
end

function _train_predict(nnc::NearNeighborClassifier{IndexType,LabelType}, table, test_X, k) where {IndexType,LabelType}
    A = Vector{LabelType}(undef, length(test_X))
    w = Vector{Float64}(undef, length(nnc.le.labels))

    for i in 1:length(test_X)
        w .= 0.0
        row = table[i]
        for j in 1:k
            label, _d = row[j]
            if nnc.weight == :uniform
                w[label] += 1
            else
                w[label] += 1.0 / (1.0 + _d)
            end
        end

        score, label = findmax(w)
        A[i] = inverse_transform(nnc.le, label)
    end

    A
end

function optimize!(nnc::NearNeighborClassifier, scorefun::Function; runs=3, trainratio=0.5, testratio=0.5, folds=0, folds_shuffle=true)
    mem = Dict{Tuple,Float64}()

    function f(train_X, train_y, test_X, test_y)
        _nnc = NearNeighborClassifier(nnc.dist, train_X, train_y)
        kmax = sqrt(length(train_y)) |> round |> Int
        table = _train_create_table(_nnc.dist, train_X, train_y, test_X, kmax)
        k = 2
        while k <= kmax
            for weight in (:uniform, :distance)
                _nnc.weight = weight
                _nnc.k = k - 1
                pred_y = _train_predict(_nnc, table, test_X, _nnc.k)
                score = scorefun(test_y, pred_y)
                key = (k - 1, weight)
                mem[key] = get(mem, key, 0.0) + score
            end
            k += k
        end
        0
    end

    if folds > 1
        kfolds(f, nnc.X.db, nnc.y, folds=folds, shuffle=folds_shuffle)
        bestlist = [(score/folds, conf) for (conf, score) in mem]
    else
        montecarlo(f, nnc.X.db, nnc.y, runs=runs, trainratio=trainratio, testratio=testratio)
        bestlist = [(score/runs, conf) for (conf, score) in mem]
    end

    sort!(bestlist, by=x -> (-x[1], x[2][1]))
    best = bestlist[1]
    nnc.k = best[2][1]
    nnc.weight = best[2][2]

    bestlist
end
