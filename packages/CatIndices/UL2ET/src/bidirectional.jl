using CustomUnitRanges
include(CustomUnitRanges.filename_for_urange)  # defines URange

mutable struct BidirectionalVector{T} <: AbstractVector{T}
    data::Vector{T}
    offset::Int
end
BidirectionalVector(v::AbstractVector{T}, inds::AbstractUnitRange) where {T} =
    BidirectionalVector(copyelts(v), first(inds)-1)
BidirectionalVector(v::AbstractVector) = BidirectionalVector(v, Base.axes1(v))

# copies but doesn't preserve the axes
function copyelts(v::AbstractVector{T}) where T
    inds = Base.axes1(v)
    n = length(inds)
    dest = Array{T}(undef, n)
    for (vel, j) in zip(v, 1:n)
        dest[j] = vel
    end
    dest
end

Base.axes1(v::BidirectionalVector) = URange(1+v.offset, length(v.data)+v.offset)
Base.axes( v::BidirectionalVector) = (Base.axes1(v),)
Base.size( v::BidirectionalVector) = (length(v),)
Base.length(v::BidirectionalVector) = length(v.data)

function Base.similar(v::AbstractArray, T::Type, inds::Tuple{URange})
    inds1 = inds[1]
    n = length(inds1)
    BidirectionalVector(Array{T}(undef, n), first(inds1)-1)
end

function Base.similar(f::Union{Function,Type}, inds::Tuple{URange})
    inds1 = inds[1]
    n = length(inds1)
    BidirectionalVector(f(Base.OneTo(n)), first(inds1)-1)
end

@inline function Base.getindex(v::BidirectionalVector, i::Int)
    @boundscheck checkbounds(v, i)
    @inbounds ret = v.data[i-v.offset]
    ret
end

@inline function Base.setindex!(v::BidirectionalVector, val, i::Int)
    @boundscheck checkbounds(v, i)
    @inbounds v.data[i-v.offset] = val
    val
end

Base.push!(v::BidirectionalVector, x) = (push!(v.data, x); v)
Base.pop!(v::BidirectionalVector) = pop!(v.data)
Base.append!(v::BidirectionalVector, collection2) = (append!(v.data, collection2); v)
function Base.prepend!(v::BidirectionalVector, collection2)
    v.offset -= length(collection2)
    prepend!(v.data, collection2)
    v
end
function Base.popfirst!(v::BidirectionalVector)
    v.offset += 1
    popfirst!(v.data)
end
function Base.pushfirst!(v::BidirectionalVector, x)
    v.offset -= 1
    pushfirst!(v.data, x)
    v
end
@inline function Base.pushfirst!(v::BidirectionalVector, y...)
    v.offset -= length(y)
    pushfirst!(v.data, y...)
    v
end


function deletetail!(v::BidirectionalVector, n::Integer)
    deleteat!(v.data, length(v.data)-n+1:length(v.data))
    v
end
function deletehead!(v::BidirectionalVector, n::Integer)
    v.offset += n
    deleteat!(v.data, 1:n)
    v
end
