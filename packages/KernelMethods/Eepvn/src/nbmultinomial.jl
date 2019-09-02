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

export MultinomialKernel

mutable struct MultinomialKernel <: NaiveBayesKernel
    acc_given_y::Matrix{Float64}
    smoothing::Float64
end

function MultinomialKernel(X::AbstractVector{ItemType}, y::AbstractVector{Int}, nlabels::Int; smoothing::Float64=0.0) where ItemType
    C = zeros(Float64, length(X[1]), nlabels)

    @inbounds for i in 1:length(X)
        label = y[i]
        for (j, x) in enumerate(X[i])
            C[j, label] += x
        end
    end

    MultinomialKernel(C, smoothing)
end

function kernel_prob(nbc::NaiveBayesClassifier, kernel::MultinomialKernel, x::AbstractVector{Float64})::Vector{Float64}
    n = length(nbc.le.labels)
    scores = zeros(Float64, n)
    for i in 1:n
        pxy = 1.0
        py = nbc.probs[i]
        for j in 1:length(x)
            den = kernel.acc_given_y[j, i] + kernel.smoothing * n
            pxy *= (x[j] + kernel.smoothing) / den
        end
        scores[i] = py * pxy
    end

    scores
end
