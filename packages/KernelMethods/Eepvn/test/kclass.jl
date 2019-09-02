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

using Test
using StatsBase
include("loaddata.jl")

@testset "encode by farthest points" begin
    using KernelMethods.KMap: KernelClassifier, predict
    using KernelMethods.Scores: accuracy, recall
    X, y = loadiris()
    kmodel = KernelClassifier(X, y, folds=3, ensemble_size=3, size=31, score=accuracy)
    yh = predict(kmodel, X)
    acc = mean(y .== yh)
    @info "===== KernelClassifier accuracy: $acc"
    @test acc > 0.9
end
