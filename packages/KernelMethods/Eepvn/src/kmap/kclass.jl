# Copyright 2018,2019 Eric S. Tellez <eric.tellez@infotec.mx>
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
export KernelClassifier, KConfigurationSpace, predict, predict_one

using KernelMethods
import KernelMethods.Scores: accuracy, recall, precision, f1, precision_recall
import KernelMethods.CrossValidation: montecarlo, kfolds
import KernelMethods.Supervised: NearNeighborClassifier, NaiveBayesClassifier, optimize!, predict, predict_one, transform, inverse_transform
import SimilaritySearch: l2_distance, angle_distance
# import KernelMethods.KMap: sqrt_criterion, log_criterion, change_criterion
# using KernelMethods.KMap: fftraversal, sqrt_criterion, change_criterion, log_criterion, kmap
using KernelMethods.Kernels: gaussian_kernel, cauchy_kernel, sigmoid_kernel, tanh_kernel, linear_kernel

struct KConfigurationSpace
    normalize
    distances
    kdistances
    sampling
    kernels
    reftypes
    classifiers
    
    function KConfigurationSpace(;
        normalize=[true, false],
        distances=[l2_distance, cosine_distance],
        kdistances=[l2_distance, cosine_distance],
        sampling=vcat(
            [(method=fftraversal, stop=x) for x in (sqrt_criterion, log_criterion, change_criterion)],
            [(method=dnet, kfun=x) for x in (log2, x -> min(x, log2(x)^2))]
        ),
        #kernels=[linear_kernel, gaussian_kernel, sigmoid_kernel, cauchy_kernel, tanh_kernel],
        kernels=[linear_kernel, gaussian_kernel, tanh_kernel],
        #reftypes=[:centroids, :centers],
        reftypes=[:centroids, :centers],
        #classifiers=[NearNeighborClassifier, NaiveBayesClassifier]
        classifiers=[NearNeighborClassifier]
        )
        new(normalize, distances, kdistances, sampling, kernels, reftypes, classifiers)
    end
    
end


struct KConfiguration
    normalize
    dist
    kdist
    kernel
    net
    reftype
    classifier
end

function randconf(space::KConfigurationSpace)
    kdist = rand(space.kdistances)
    normalize = (kdist in (cosine_distance, angle_distance)) || rand(space.normalize)

    c = KConfiguration(
        normalize,
        rand(space.distances),
        kdist,
        rand(space.kernels),
        rand(space.sampling),
        rand(space.reftypes),
        rand(space.classifiers)
    )

    c
end

function randconf(space::KConfigurationSpace, num::Integer)
    [randconf(space) for i in 1:num]
end

struct KernelClassifierType{ItemType}
    kernel
    refs::Vector{ItemType}
    classifier
    conf::KConfiguration
end

"""
Searches for a competitive configuration in a parameter space using random search
    """
    function KernelClassifier(X, y;
        folds=3,
        score=recall,
        size=32,
        ensemble_size=3,
        space=KConfigurationSpace()
        )
        
        bestlist = []
        tabu = Set()
        dtype = typeof(X[1])
        
        for conf in randconf(space, size)
            if conf in tabu
                continue
            end
            
            @info "testing configuration $(conf), data-type $(typeof(X))"
            push!(tabu, conf)
            dist = conf.dist
            kdist = conf.kdist
            refs = Vector{dtype}()
            dmax = 0.0
            
            if conf.kernel in (cauchy_kernel, gaussian_kernel, sigmoid_kernel, tanh_kernel)
                kernel = conf.kernel(dist, dmax/2)
            elseif conf.kernel == linear_kernel
                kernel = conf.kernel(dist)
            else
                kernel = conf.kernel
            end
            
            if conf.net.method == fftraversal
                function pushcenter1(c, _dmax)
                    push!(refs, X[c])
                    dmax = _dmax
                end

                fftraversal(pushcenter1, dist, X, conf.net.stop())
                # after fftraversal refs is populated
                R = fit(Sequential, refs)
                @info "computing kmap, conf: $conf"
                if conf.reftype == :centroids
                    a = [centroid!(X[plist]) for plist in invindex(dist, X, R) if length(plist) > 0]
                    M = kmap(X, kernel, a)
                else
                    M = kmap(X, kernel, refs)
                end
            elseif conf.net.method == dnet
                function pushcenter2(c, dmaxlist)
                    if conf.reftype == :centroids
                        a = vcat([X[c]], X[[p.objID for p in dmaxlist]]) |> centroid!
                        push!(refs, a)
                    else
                        push!(refs, X[c])
                    end
                    
                    dmax += last(dmaxlist).dist
                end
                
                k = conf.net.kfun(length(X)) |> ceil |> Int
                dnet(pushcenter2, dist, X, k)
                if k == length(refs)
                    @info "$k != $(length(refs))"
                    @info refs
                    error("incorrect number of references, $conf")
                end
                @info "computing kmap, conf: $conf"
                M = kmap(X, kernel, refs)
                dmax /= length(refs)
            end

            if conf.normalize
                for m in M
                    normalize!(m)
                end
            end

            @info "creating and optimizing classifier, conf: $conf"
            if conf.classifier == NearNeighborClassifier
                classifier = NearNeighborClassifier(kdist, M, y)
                best = optimize!(classifier, score, folds=folds)[1]
            else
                classifier = NaiveBayesClassifier(M, y)
                best = optimize!(classifier, M, y, score, folds=folds)[1]
            end
            
            model = KernelClassifierType(kernel, refs, classifier, conf)
            push!(bestlist, (best[1], model))
            @info "score: $(best[1]), conf: $conf"
            sort!(bestlist, by=x->-x[1])
            
            if length(bestlist) > ensemble_size
                bestlist = bestlist[1:ensemble_size]
            end
        end
        
        @info "final scores: ", [b[1] for b in bestlist]
        # @show [b[1] for b in bestlist]
        [b[2] for b in bestlist]
    end
    
    function predict(kmodel::AbstractVector{KernelClassifierType{ItemType}}, vector) where {ItemType}
        [predict_one(kmodel, x) for x in vector]
    end
    
    function predict_one(kmodel::AbstractVector{KernelClassifierType{ItemType}}, x) where {ItemType}
        C = Dict()
        for m in kmodel
            label = predict_one(m, x)
            C[label] = get(C, label, 0) + 1
        end
        
        counter = [(c, label) for (label, c) in C]
        sort!(counter, by=x->-x[1])
        
        # @show counter
        counter[1][end]
    end
    
    function predict_one(kmodel::KernelClassifierType{ItemType}, x) where {ItemType}
        kernel = kmodel.kernel
        refs = kmodel.refs
        
        vec = Vector{Float64}(undef, length(refs))
        for i in 1:length(refs)
            vec[i] = kernel(x, refs[i])
        end
        
        if kmodel.conf.normalize
            normalize!(vec)
        end

        predict_one(kmodel.classifier, vec)
    end
    