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


module CrossValidation
using Random

export montecarlo, kfolds

function montecarlo(evalfun::Function, X::Vector{ItemType}, y::Vector{LabelType}; runs::Int=3, trainratio=0.7, testratio=0.3) where {ItemType, LabelType}
    Z = zip(X, y) |> collect
    R = Float64[]
    for i in 1:runs
        shuffle!(Z)
        sep = floor(Int, length(Z) * trainratio)
        last = min(length(Z), sep + 1 + floor(Int, length(Z) * testratio))
        train = @view Z[1:sep]
        test = @view Z[1+sep:last]
        s = evalfun([z[1] for z in train], [z[2] for z in train], [z[1] for z in test], [z[2] for z in test])
        push!(R, s)
    end

    return R
end

function kfolds(evalfun::Function, X::Vector{ItemType}, y::Vector{LabelType}; folds::Int=3, shuffle=true) where {ItemType, LabelType}
    Z = zip(X, y) |> collect
    if shuffle
        shuffle!(Z)
    end
    R = Float64[]
    bsize = floor(Int, length(Z) / folds)
    begin
        test = @view Z[1:bsize]
        train = @view Z[bsize+1:end]
        s = evalfun([z[1] for z in train], [z[2] for z in train], [z[1] for z in test], [z[2] for z in test])
        push!(R, s)
    end

    for i in 1:folds-1
        train = vcat(Z[1:bsize*i], Z[bsize*(i+1)+1:end])
        test = @view Z[bsize*i+1:bsize*(i+1)]
        s = evalfun([z[1] for z in train], [z[2] for z in train], [z[1] for z in test], [z[2] for z in test])
        push!(R, s)
    end

    return R
end

end
