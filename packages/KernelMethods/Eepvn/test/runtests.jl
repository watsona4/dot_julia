# Copyright 2017 Eric S. Tellez
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

using KernelMethods
import KernelMethods.Scores: accuracy, recall, precision, f1, precision_recall
import KernelMethods.CrossValidation: montecarlo, kfolds
import KernelMethods.Supervised: NearNeighborClassifier, NaiveBayesClassifier, optimize!, predict, predict_proba, transform, inverse_transform
import SimilaritySearch: l2_distance, fit, Sequential
# import KernelMethods.Nets: KlusterClassifier
using Test


@testset "Scores" begin
    @test accuracy([1,1,1,1,1], [1,1,1,1,1]) == 1.0
    @test accuracy([1,1,1,1,1], [0,0,0,0,0]) == 0.0
    @test accuracy([1,1,1,1,0], [0,1,1,1,1]) == 0.6
    @test precision_recall([0,1,1,1,0,1], [0,1,1,1,1,1]) == (0.8333333333333334, 0.8333333333333334, Dict(0 => (1.0, 0.5, 2), 1 => (0.8, 1.0, 4)))
    @test precision([0,1,1,1,0,1], [0,1,1,1,1,1]) == 0.9
    @test recall([0,1,1,1,0,1], [0,1,1,1,1,1]) == 0.75
    @test precision([0,1,1,1,0,1], [0,1,1,1,1,1], weight=:weighted) == (1.0 * 2/6 + 0.8 * 4/6) / 2
    @test recall([0,1,1,1,0,1], [0,1,1,1,1,1], weight=:weighted) == (0.5 * 2/6 + 1.0 * 4/6) / 2
    @test f1([0,1,1,1,0,1], [0,1,1,1,1,1], weight=:macro) ≈ (2 * 0.5 / 1.5 + 2 * 0.8 / 1.8) / 2
    #@show f1([0,1,1,1,0,1], [0,1,1,1,1,1], weight=:weighted) # ≈ (2/6 * 2 * 0.5 / 1.5 + 4 / 6 * 2 * 0.8 / 1.8) / 2
end

@testset "CrossValidation" begin
    data = collect(1:100)
    function f(train_X, train_y, test_X, test_y)
        @test train_X == train_y
        @test test_X == test_y
        @test length(train_X ∩ test_X) == 0
        @test length(train_X ∪ test_X) >= 99
        1
    end
    @test montecarlo(f, data, data, runs=10) |> sum == 10
    @test kfolds(f, data, data, folds=10, shuffle=true) |> sum == 10
end

include("oneclass.jl")
include("loaddata.jl")

@testset "KNN" begin
    X, y = loadiris()
    nnc = NearNeighborClassifier(l2_distance, X, y)
    @test optimize!(nnc, accuracy, runs=5, trainratio=0.2, testratio=0.2)[1][1] > 0.8
    @test optimize!(nnc, accuracy, runs=5, trainratio=0.3, testratio=0.3)[1][1] > 0.8
    @test optimize!(nnc, accuracy, runs=5, trainratio=0.7, testratio=0.3)[1][1] > 0.8

    @test optimize!(nnc, accuracy, folds=2)[1][1] > 0.8
    @test optimize!(nnc, accuracy, folds=3)[1][1] > 0.8
    @test optimize!(nnc, accuracy, folds=5)[1][1] > 0.85
    @test optimize!(nnc, accuracy, folds=10)[1][1] > 0.85
    @show optimize!(nnc, accuracy, folds=5)
    @test sum([maximum(x) for x in predict_proba(nnc, X, smoothing=0)])/ length(X) > 0.8 ## close to have all ones, just in case
    @test sum([maximum(x) for x in predict_proba(nnc, X, smoothing=0.01)])/ length(X) > 0.8 ## close to have all ones, just in case
end

@testset "NB" begin
    X, y = loadiris()
    nbc = NaiveBayesClassifier(X, y)
    @test optimize!(nbc, X, y, accuracy, runs=5, trainratio=0.2, testratio=0.2)[1][1] > 0.8
    @test optimize!(nbc, X, y, accuracy, runs=5, trainratio=0.3, testratio=0.3)[1][1] > 0.8
    @test optimize!(nbc, X, y, accuracy, runs=5, trainratio=0.5, testratio=0.5)[1][1] > 0.8
    @test optimize!(nbc, X, y, accuracy, runs=5, trainratio=0.7, testratio=0.3)[1][1] > 0.8
    @show optimize!(nbc, X, y, accuracy, runs=5, trainratio=0.7, testratio=0.3)
end

include("knnreg.jl")
include("kmap.jl")

include("kclass.jl")
