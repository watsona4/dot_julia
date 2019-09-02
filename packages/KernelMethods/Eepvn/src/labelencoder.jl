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

export LabelEncoder, transform, inverse_transform

import Base: broadcastable

struct LabelEncoder{LabelType}
    imap::Dict{LabelType,Int}
    labels::Vector{LabelType}
    freqs::Vector{Int}

    function LabelEncoder(y::AbstractVector{LabelType}) where LabelType
        L = Dict{LabelType,Int}()
        for c in y
            L[c] = get(L, c, 0) + 1
        end

        labels = collect(keys(L))
        sort!(labels)
        freqs = [L[c] for c in labels]
        imap = Dict(c => i for (i, c) in enumerate(labels))
        new{LabelType}(imap, labels, freqs)
    end
end

function transform(le::LabelEncoder{LabelType}, y::LabelType)::Int where LabelType
    le.imap[y]
end

function inverse_transform(le::LabelEncoder{LabelType}, y::Int)::LabelType where LabelType
    le.labels[y]
end

function broadcastable(le::LabelEncoder)
    [le]
end
