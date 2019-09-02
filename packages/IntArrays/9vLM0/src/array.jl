mutable struct IntArray{w,T<:Unsigned,n} <: AbstractArray{T,n}
    buffer::Buffer{w,T}
    size::NTuple{n,Int}
    function IntArray{w,T,n}(buffer::Buffer{w,T}, size::NTuple{n,Int}) where {w,T,n}
        if w > bitsof(T)
            error("w = $w cannot be encoded with $T")
        end
        new(buffer, size)
    end
end

# call this function when creating an array
function IntArray{w,T}(dims::NTuple{n,Int}, mmap::Bool=false) where {w,T,n}
    return IntArray{w,T,n}(Buffer{w,T}(prod(dims), mmap), dims)
end

function IntArray{w,T}(len::Integer, mmap::Bool=false) where {w,T}
    return IntArray{w,T}((len,), mmap)
end

function IntArray{w,T}(I::Integer...) where {w,T}
    return IntArray{w,T}(I)
end

function IntArray{w,T,n}(dims::NTuple{n,Int}, mmap::Bool=false) where {w,T,n}
    return IntArray{w,T}(dims, mmap)
end

function IntArray{w,T,n}(array::AbstractArray{T,n}) where {w,T,n}
    iarray = IntArray{w,T}(size(array))
    @inbounds for i in eachindex(array)
        iarray[i] = array[i]
    end
    return iarray
end

function Base.convert(::Type{IntArray{w,T,n}}, array::AbstractArray{T,n}) where {w,T,n}
    return IntArray{w,T,n}(array)
end

# resolve a method ambiguity with Base
Base.convert(::Type{IntArray{w,T,n}}, array::IntArray{w,T,n}) where {w,T,n} = array

function IntArray{w}(array::AbstractArray{T,n}) where {w,T,n}
    return IntArray{w,T,n}(array)
end

function Base.convert(::Type{IntArray{w}}, array::AbstractArray{T,n}) where {w,T,n}
    return convert(IntArray{w,T,n}, array)
end

Base.IndexStyle(::Type{<:IntArray}) = Base.IndexLinear()

Base.size(array::IntArray) = array.size
Base.length(array::IntArray) = prod(array.size)
Base.sizeof(array::IntArray) = sizeof(array.buffer.data)

@inline function Base.getindex(array::IntArray{w,T}, i::Integer) where {w,T}
    @boundscheck checkbounds(array, i)
    return unsafe_getindex(array, i)
end

@inline function unsafe_getindex(array::IntArray{w,T}, i::Integer) where {w,T}
    return array.buffer[i] % T
end

# when I removed type parameters, array[i] fell into an infinite recursive call...
function Base.getindex(array::IntArray{w,T}, i::Integer, j::Integer...) where {w,T}
    @boundscheck checkbounds(array, i, j...)
    return unsafe_getindex(array, LinearIndices(array.size)[i, j...])
end

@inline function Base.setindex!(array::IntArray, x::Unsigned, i::Integer)
    @boundscheck checkbounds(array, i)
    return unsafe_setindex!(array, x, i)
end

@inline function unsafe_setindex!(array::IntArray{w,T}, x::Integer, i::Integer) where {w,T}
    array.buffer[i] = x % T
    return array
end

function Base.setindex!(array::IntArray{w,T}, x::Integer, i::Integer, j::Integer...) where {w,T}
    @boundscheck checkbounds(array, i, j...)
    return unsafe_setindex!(array, x, LinearIndices(array.size)[i, j...])
end


function Base.similar(array::IntArray{w}, ::Type{T}, dims::Dims) where {w,T<:Unsigned}
    n = length(dims)
    IntArray{w,T,n}(dims)
end


function Base.fill!(array::IntArray{w,T}, x::Integer) where {w,T}
    if x == 0
        fill0!(array.buffer)
    elseif x == (1 << w) - 1
        fill1!(array.buffer)
    else
        fill!(array.buffer, x % T)
    end
    return array
end


function Base.copy!(a::IntArray{w}, b::IntArray{w}) where {w}
    len_a = length(a)
    len_b = length(b)
    if len_a < len_b
        throw(BoundsError())
    elseif len_a == len_b
        copyto!(a.buffer.data, b.buffer.data)
    else
        for i in 1:len_b
            a[i] = b[i]
        end
    end
    return a
end
