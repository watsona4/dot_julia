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

export GaussianKernel

# using Distributions

struct GaussianKernel <: NaiveBayesKernel
    mean_given_y::Matrix{Float64}
    var_given_y::Matrix{Float64}
end

function GaussianKernel(X::AbstractVector{ItemType}, y::AbstractVector{Int}, nlabels::Int) where ItemType
    dim = length(X[1])
    occ = ones(Float64, dim, nlabels)
    C = zeros(Float64, dim, nlabels)
    V = zeros(Float64, dim, nlabels)
    # α = 1 / length(X)

    @inbounds for i in 1:length(X)
        label = y[i]
        for (j, x) in enumerate(X[i])
            C[j, label] += x
            occ[j, label] += 1
        end
    end
    C = C ./ occ

    @inbounds for i in 1:length(X)
        label = y[i]
        for (j, x) in enumerate(X[i])
           V[j, label] += (x - C[j, label])^2
        end
    end

    V = V ./ occ
    GaussianKernel(C, V)
end

function kernel_prob(nbc::NaiveBayesClassifier, kernel::GaussianKernel, x::AbstractVector{Float64})::Vector{Float64}
    n = length(nbc.le.labels)
    scores = zeros(Float64, n)
    @inbounds for i in 1:n
        pxy = 1.0
        py = nbc.probs[i]
        for j in 1:length(x)
            var2 = 2 * kernel.var_given_y[j, i]
            a = 1 / sqrt(pi * var2)
            # a = 1/sqrt(pi * abs(var2))
            pxy *= a * exp(-(x[j] - kernel.mean_given_y[j, i])^2 / var2)
        end
        scores[i] = py * pxy
    end

    scores
end
