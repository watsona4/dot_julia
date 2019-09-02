const IntMatrix{w,T} = IntArray{w,T,2}

function IntMatrix{w,T}(m::Integer, n::Integer, mmap::Bool=false) where {w,T}
    return IntArray{w,T}((m, n), mmap)
end

function IntMatrix{w,T}(mmap::Bool=false) where {w,T}
    return IntArray{w,T}((0, 0), mmap)
end

function IntMatrix{w}(matrix::AbstractMatrix{T}) where {w,T}
    return IntArray{w,T,2}(matrix)
end

function Base.convert(::Type{IntMatrix{w}}, matrix::AbstractMatrix{T}) where {w,T}
    return convert(IntArray{w,T,2}, matrix)
end
