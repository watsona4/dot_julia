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

module Scores
using StatsBase
export accuracy, precision_recall, precision, recall, f1, scores

"""
It computes the recall between the gold dataset and the list of predictions `predict`

It applies the desired weighting scheme for binary and multiclass problems
- `:macro` performs a uniform weigth to each class
- `:weigthed` the weight of each class is proportional to its population in gold
- `:micro` returns the global recall, without distinguishing among classes
"""
function recall(gold, predict; weight=:macro)::Float64
    precision, recall, precision_recall_per_class = precision_recall(gold, predict)
    if weight == :macro
        mean(x -> x.second[2], precision_recall_per_class)
    elseif weight == :weighted
        mean(x -> x.second[2] * x.second[3] / length(gold), precision_recall_per_class)
    elseif :micro
        recall
    else
        throw(Exception("Unknown weighting method $weight"))
    end
end

"""
It computes the precision between the gold dataset and the list of predictions `predict`

It applies the desired weighting scheme for binary and multiclass problems
- `:macro` performs a uniform weigth to each class
- `:weigthed` the weight of each class is proportional to its population in gold
- `:micro` returns the global precision, without distinguishing among classes
"""
function precision(gold, predict; weight=:macro)::Float64
    precision, recall, precision_recall_per_class = precision_recall(gold, predict)
    if weight == :macro
        mean(x -> x.second[1], precision_recall_per_class)
    elseif weight == :weighted
        mean(x -> x.second[1] * x.second[3] / length(gold), precision_recall_per_class)
    elseif weight == :micro
        precision
    else
        throw(Exception("Unknown weighting method $weight"))
    end
end

"""
It computes the F1 score between the gold dataset and the list of predictions `predict`

It applies the desired weighting scheme for binary and multiclass problems
- `:macro` performs a uniform weigth to each class
- `:weigthed` the weight of each class is proportional to its population in gold
- `:micro` returns the global F1, without distinguishing among classes
"""
function f1(gold, predict; weight=:macro)::Float64
    precision, recall, precision_recall_per_class = precision_recall(gold, predict)
    if weight == :macro
        mean(x -> 2 * x.second[1] * x.second[2] / (x.second[1] + x.second[2]), precision_recall_per_class)
    elseif weight == :weighted
        mean(x -> 2 * x.second[1] * x.second[2] / (x.second[1] + x.second[2]) * x.second[3]/length(gold), precision_recall_per_class)
    elseif weight == :micro
        2 * (precision * recall) / (precision + recall)
    else
        throw(Exception("Unknown weighting method $weight"))
    end
end

"""
Computes precision, recall, and f1 scores, for global and per-class granularity
"""
function scores(gold, predicted)
    precision, recall, precision_recall_per_class = precision_recall(gold, predicted)
    m = Dict(
        :micro_f1 => 2 * precision * recall / (precision + recall),
		:precision => precision,
		:recall => recall,
		:class_f1 => Dict(),
		:class_precision => Dict(),
		:class_recall => Dict()
    )

    for (k, v) in precision_recall_per_class
        m[:class_f1][k] = 2 * v[1] * v[2] / (v[1] + v[2])
		m[:class_precision][k] = v[1]
		m[:class_recall][k] = v[2]
    end
    
    m[:macro_recall] = mean(values(m[:class_recall]))
    m[:macro_f1] = mean(values(m[:class_f1]))
    m[:accuracy] = accuracy(gold, predicted)
    m
end

"""
It computes the global and per-class precision and recall values between the gold standard
and the predicted set
"""
function precision_recall(gold, predicted)
    labels = unique(gold)
    M = Dict{typeof(labels[1]), Tuple}()
    tp_ = 0
    tn_ = 0
    fn_ = 0
    fp_ = 0

    for label in labels
        lgold = label .== gold
        lpred = label .== predicted

        tp = 0
        tn = 0
        fn = 0
        fp = 0
        for i in 1:length(lgold)
            if lgold[i] == lpred[i]
                if lgold[i]
                    tp += 1
                else
                    tn += 1
                end
            else
                if lgold[i]
                    fn += 1
                else
                    fp += 1
                end
            end
        end

        tp_ += tp
        tn_ += tn
        fn_ += fn
        fp_ += fp
        M[label] = (tp / (tp + fp), tp / (tp + fn), sum(lgold) |> Int)  # precision, recall, class-population
    end

    tp_ / (tp_ + fp_), tp_ / (tp_ + fn_), M
end

"""
It computes the accuracy score between the gold and the predicted sets
"""
function accuracy(gold, predicted)
    #  mean(gold .== predicted)
    c = 0
    for i in 1:length(gold)
        c += (gold[i] == predicted[i])
    end

    c / length(gold)
end

######### Regression ########

export pearson, spearman, isqerror
"""
Pearson correlation score
"""
function pearson(X::AbstractVector{F}, Y::AbstractVector{F}) where {F <: AbstractFloat}
    X̄ = mean(X)
    Ȳ = mean(Y)
    n = length(X)
    sumXY = 0.0
    sumX2 = 0.0
    sumY2 = 0.0
    for i in 1:n
        x, y = X[i], Y[i]
        sumXY += x * y
        sumX2 += x * x
        sumY2 += y * y
    end
    num = sumXY - n * X̄ * Ȳ
    den = sqrt(sumX2 - n * X̄^2) * sqrt(sumY2 - n * Ȳ^2)
    num / den
end

"""
Spearman rank correleation score
"""
function spearman(X::AbstractVector{F}, Y::AbstractVector{F}) where {F <: AbstractFloat}
    n = length(X)
    x = invperm(sortperm(X))
    y = invperm(sortperm(Y))
    d = x - y
    1 - 6 * sum(d.^2) / (n * (n^2 - 1))
end

"""
Negative squared error (to be used for maximizing algorithms)
"""
function isqerror(X::AbstractVector{F}, Y::AbstractVector{F}) where {F <: AbstractFloat}
    n = length(X)
    d = 0.0

    @inbounds for i in 1:n
        d += (X[i] - Y[i])^2
    end

    -d
end

end
