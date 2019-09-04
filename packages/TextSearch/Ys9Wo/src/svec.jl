#  Copyright 2016-2019 Eric S. Tellez <eric.tellez@infotec.mx>
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

import Base: +, *, ==, length, transpose
import LinearAlgebra: dot
import SimilaritySearch: normalize!, cosine_distance, angle_distance
export SparseVector, SparseVectorEntry, dot, cosine_distance, angle_distance, normalize!

mutable struct SparseVectorEntry
    id::UInt64
    weight::Float64
end

struct SparseVector
    tokens::Vector{SparseVectorEntry}
    # invnorm::Float64

    function SparseVector(tokens::Vector{SparseVectorEntry}; sort=true)
        sort && sort!(tokens, by=x->x.id)
        new(tokens)
    end
end

function SparseVector(bow::Dict{I, F}) where I <: Integer where F <: Real
    M = Vector{SparseVectorEntry}(undef, length(bow))
    i = 1

    for p in bow
        M[i] = SparseVectorEntry(convert(UInt64, p.first), convert(Float64, p.second))
        i+=1
    end

    SparseVector(M, sort=true)
end

function SparseVector(bow::Dict{Symbol, F}) where F <: Real
    M = Vector{SparseVectorEntry}(undef, length(bow))
    i = 1

    for p in bow
        M[i] = SparseVectorEntry(hash(p.first), convert(Float64, p.second))
        i+=1
    end

    SparseVector(M, sort=true)
end

function normalize!(matrix::AbstractVector{SparseVector})
    for bow in matrix
        normalize!(bow)
    end
end

function normalize!(bow::SparseVector)
    normalize!(bow.tokens)
    bow
end

function normalize!(tokens::Vector{SparseVectorEntry})
    xnorm::Float64 = 0.0
    @inbounds @simd for i in 1:length(tokens)
        xnorm += tokens[i].weight ^ 2
    end

    (xnorm <= eps(Float64)) && error("A valid SparseVector object cannot have a zero norm $xnorm -- tokens: $tokens")
    xnorm = 1.0/sqrt(xnorm)

    @inbounds @simd for i in 1:length(tokens)
        tokens[i].weight *= xnorm;
    end

    tokens
end

"""
Number of items different of zero
"""
length(a::SparseVector) = length(a.tokens)


"""
cosine_distance

Computes the cosine_distance between two SparseVector objects (sparse vectors)

It supposes that all vectors are normalized (see `normalize!` function)

"""
function cosine_distance(a::SparseVector, b::SparseVector)::Float64
    return 1.0 - dot(a, b)  #
end

const π_2 = π / 2
"""
angle_distance

Computes the angle  between two SparseVector objects (sparse vectors).

It supposes that all vectors are normalized (see `normalize!` function)

"""
function angle_distance(a::SparseVector, b::SparseVector)
    d = dot(a, b)

    if d <= -1.0
        return π
    elseif d >= 1.0
        return 0.0
    elseif d == 0  # turn around for zero vectors, in particular for denominator=0
        return π_2
    else
        return acos(d)
    end
end

function dot(a::SparseVector, b::SparseVector)::Float64
    n1 = length(a.tokens)
    n2 = length(b.tokens)
    # (n1 == 0 || n2 == 0) && return 0.0

    s::Float64 = 0.0
    i = 1
    j = 1

    @inbounds while i <= n1 && j <= n2
        c = cmp(a.tokens[i].id, b.tokens[j].id)
        if c == 0
            s += a.tokens[i].weight * b.tokens[j].weight
            i += 1
            j += 1
        elseif c < 0
            i += 1
        else
            j += 1
        end
    end

    s
end

function cosine(a::SparseVector, b::SparseVector)::Float64
    return dot(a, b) # * a.invnorm * b.invnorm # it is already normalized
end

"""
   vbow1 + vbow2

   Computes the sum of two SparseVector vectors
"""
function +(a::SparseVector, b::SparseVector)
    vec = Vector{SparseVectorEntry}()
    n1 = length(a.tokens)
    n2 = length(b.tokens)
    sizehint!(vec, max(n1, n2))


    i = 1
    j = 1
    @inbounds while i <= n1 && j <= n2
        c = cmp(a.tokens[i].id, b.tokens[j].id)
        if c == 0
            push!(vec, SparseVectorEntry(a.tokens[i].id, a.tokens[i].weight + b.tokens[j].weight))
            i += 1
            j += 1
        elseif c < 0
            push!(vec, SparseVectorEntry(a.tokens[i].id, a.tokens[i].weight))
            i += 1
        else
            push!(vec, SparseVectorEntry(b.tokens[j].id, b.tokens[j].weight))
            j += 1
        end    
    end

    @inbounds while i <= n1
        push!(vec, SparseVectorEntry(a.tokens[i].id, a.tokens[i].weight))
        i += 1
    end

    @inbounds while j <= n2
        push!(vec, SparseVectorEntry(b.tokens[j].id, b.tokens[j].weight))
        j += 1
    end

    SparseVector(vec)
end

#Base::+(a::SparseVector, b::SparseVector) = sum_vbow

"""
   vbow1 * vbow2

   Point to point product
"""
function *(a::SparseVector, b::SparseVector)
    vec = Vector{SparseVectorEntry}()
    n1 = length(a.tokens)
    n2 = length(b.tokens)
    sizehint!(vec, min(n1, n2))

    i = 1
    j = 1
    @inbounds while i <= n1 && j <= n2
        c = cmp(a.tokens[i].id, b.tokens[j].id)
        if c == 0
            push!(vec, SparseVectorEntry(a.tokens[i].id, a.tokens[i].weight * b.tokens[j].weight))
            i += 1
            j += 1
        elseif c < 0
            i += 1
        else
            j += 1
        end
    end

    SparseVector(vec)
end

function ==(a::SparseVectorEntry, b::SparseVectorEntry)
    a.id == b.id && a.weight == b.weight
end

function ==(a::SparseVector, b::SparseVector)
    if length(a.tokens) == length(b.tokens)
        for i in 1:length(a.tokens)
            if a.tokens[i] != b.tokens[i]
                return false
            end
        end

        return true
    else
        return false
    end
end

function *(a::SparseVector, b::F) where {F <: Real}
    vec = Vector{SparseVectorEntry}()
    n=length(a.tokens)
    sizehint!(vec, n)
    i = 1
    @inbounds while i <= n
        push!(vec, SparseVectorEntry(a.tokens[i].id, a.tokens[i].weight*b))
        i += 1
    end

    return SparseVector(vec)
end

function *(b::F, a::SparseVector) where {F <: Real}
    return a * b
end

function transpose(matrix::AbstractVector{SparseVector})
    M = Dict{UInt, Vector{SparseVectorEntry}}()

    for (objID, vector) in enumerate(matrix)
        for token in vector.tokens
            wt = SparseVectorEntry(objID, token.weight)
            if haskey(M, token.id)
                push!(M[token.id], wt)
            else
                M[token.id] = [wt]
            end
        end
    end
    
    M
end
