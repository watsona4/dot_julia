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

include("loaddata.jl")

@testset "encode by farthest points" begin
    using KernelMethods.KMap: fftraversal, sqrt_criterion, change_criterion, log_criterion, kmap
    using KernelMethods.Scores: accuracy
    using KernelMethods.Supervised: NearNeighborClassifier, optimize!
    using SimilaritySearch: l2_distance, normalize!
    using KernelMethods.Kernels: gaussian_kernel, cauchy_kernel, sigmoid_kernel

    X, y = loadiris()
    dist = l2_distance
    # criterion = change_criterion(0.01)
    refs = Vector{typeof(X[1])}()
    dmax = 0.0
    function callback(c, _dmax)
        push!(refs, X[c])
        dmax = _dmax
    end

    fftraversal(callback, dist, X, sqrt_criterion())
    g = cauchy_kernel(dist, dmax/2)
    M = kmap(X, g, refs)
    nnc = NearNeighborClassifier(l2_distance, M, y)

    @test optimize!(nnc, accuracy, folds=2)[1][1] > 0.9
    @test optimize!(nnc, accuracy, folds=3)[1][1] > 0.9
    @test optimize!(nnc, accuracy, folds=5)[1][1] > 0.93
    @test optimize!(nnc, accuracy, folds=10)[1][1] > 0.93
    @show optimize!(nnc, accuracy, folds=5)
end

@testset "Clustering and centroid computation (with cosine)" begin
    using KernelMethods.KMap: fftraversal, sqrt_criterion, invindex, centroid!
    using SimilaritySearch: l2_distance, l1_distance, angle_distance, cosine_distance
    X, y = loadiris()
    dist = l2_distance
    refs = Vector{typeof(X[1])}()
    dmax = 0.0

    function callback(c, _dmax)
        push!(refs, X[c])
        dmax = _dmax
    end

    fftraversal(callback, dist, X, sqrt_criterion())
    R = fit(Sequential, refs)
    a = [centroid!(X[plist]) for plist in invindex(dist, X, R)]
    g = gaussian_kernel(dist, dmax/4)
    M = kmap(X, g, a)
    nnc = NearNeighborClassifier(cosine_distance, [normalize!(w) for w in M], y)

    @test optimize!(nnc, accuracy, folds=2)[1][1] > 0.8
    @test optimize!(nnc, accuracy, folds=3)[1][1] > 0.8
    @show optimize!(nnc, accuracy, folds=10)
end

@testset "encode with dnet" begin
    using KernelMethods.KMap: dnet, sqrt_criterion, change_criterion, log_criterion, kmap, fftclustering
    using KernelMethods.Scores: accuracy
    using KernelMethods.Supervised: NearNeighborClassifier, optimize!
    using SimilaritySearch: l2_distance, normalize!, angle_distance
    using KernelMethods.Kernels: gaussian_kernel, sigmoid_kernel, cauchy_kernel, tanh_kernel
    using Statistics

    X, y = loadiris()
    dist = l2_distance
    # criterion = change_criterion(0.01)
    refs = Vector{typeof(X[1])}()
    dmax = 0.0

    function callback(c, dmaxlist)
        push!(refs, X[c])
        dmax += last(dmaxlist).dist
    end

    dnet(callback, dist, X, 14)
    _dmax = dmax / length(refs)
    g = tanh_kernel(dist, _dmax)
    M = kmap(X, g, refs)
    nnc = NearNeighborClassifier(l2_distance, M, y)
    @test optimize!(nnc, accuracy, folds=2)[1][1] > 0.9
    @test optimize!(nnc, accuracy, folds=3)[1][1] > 0.9
    @test optimize!(nnc, accuracy, folds=5)[1][1] > 0.9
    @test optimize!(nnc, accuracy, folds=10)[1][1] > 0.9
    @show optimize!(nnc, accuracy, folds=5)

    C = fftclustering(angle_distance, [normalize!(x) for x in X], 21, k=3)
    
    matches = 0
    for (i, res) in enumerate(C.NN)
        label = Dict{eltype(typeof(y)),Float64}()
        for (pos, p) in enumerate(res)
            l = y[p.objID]
            label[l] = get(label, l, 0) + 1 / pos
        end

        L = [(v, k) for (k, v) in label]
        sort!(L)
        if y[i] == L[end][end]
            matches += 1
        end
    end

    @info "===== accuracy by fftclustering: $(matches/length(y))"
    @test matches/length(y) > 0.9
end
