# The contents of this file are slightly modified from InvertedIndices.jl: https://github.com/mbauman/InvertedIndices.jl/blob/7c97b19e6c75043f231f9d8e6661886b688259f1/src/InvertedIndices.jl
# Available under the following MIT "Expat" License:
#
# > Copyright (c) 2017: Matt Bauman.
# >
# > Permission is hereby granted, free of charge, to any person obtaining a copy
# > of this software and associated documentation files (the "Software"), to deal
# > in the Software without restriction, including without limitation the rights
# > to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# > copies of the Software, and to permit persons to whom the Software is
# > furnished to do so, subject to the following conditions:
# >
# > The above copyright notice and this permission notice shall be included in all
# > copies or substantial portions of the Software.
# >
# > THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# > IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# > FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# > AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# > LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# > OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# > SOFTWARE.
# >


# A very simple and primitive static array to avoid allocations while fulfilling the indexing API
struct TupleVector{T<:Tuple{Vararg{Int,N}} where N} <: AbstractVector{Int}
    data::T
end
Base.size(::TupleVector{<:NTuple{N}}) where {N} = (N,)
@inline function Base.getindex(t::TupleVector, i::Int)
    @boundscheck checkbounds(t, i)
    return @inbounds t.data[i]
end
