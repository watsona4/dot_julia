const IntVector{w,T} = IntArray{w,T,1}

function IntVector{w,T}(len::Integer, mmap::Bool=false) where {w,T}
    return IntArray{w,T}((len,), mmap)
end

function IntVector{w,T}(mmap::Bool=false) where {w,T}
    return IntArray{w,T}((0,), mmap)
end

function IntVector{w}(vector::AbstractVector{T}) where {w,T}
    return IntArray{w,T,1}(vector)
end

function Base.convert(::Type{IntVector{w}}, vector::AbstractVector{T}) where {w,T}
    return convert(IntArray{w,T,1}, vector)
end

function Base.resize!(vector::IntVector, len::Integer)
    resize!(vector.buffer, len)
    vector.size = (len,)
    return vector
end

function Base.push!(vector::IntVector, x::Integer)
    resize!(vector, length(vector) + 1)
    vector[end] = x
    return vector
end

function Base.pop!(vector::IntVector)
    x = vector[end]
    resize!(vector, length(vector) - 1)
    return x
end

function Base.append!(vec::IntVector, items::AbstractVector)
    len = length(vec)
    resize!(vec, len + length(items))
    for i in 1:lastindex(items)
        vec[len+i] = items[i]
    end
    return vec
end

function Base.reverse!(vec::IntVector, lo::Integer=1, hi::Integer=lastindex(vec))
    return reverse!(vec, Int(lo), Int(hi))
end

function Base.reverse!(vec::IntVector, lo::Int, hi::Int)
    if hi ≤ lo
        return vec
    end
    for i in 0:div(hi - lo, 2)
        vec[lo+i], vec[hi-i] = vec[hi-i], vec[lo+i]
    end
    return vec
end

radixsort(vector::IntVector) = radixsort!(copy(vector))

function radixsort!(vector::IntVector{w}) where {w}
    return radixsort!(vector, 1, length(vector), w)
end

function radixsort!(v::IntVector{w,T}, lo, hi, k) where {w,T}
    @assert 1 ≤ k ≤ w
    if lo > hi
        return v
    end
    i, j = lo, hi
    bit_k = T(1) << (k - 1)
    while i < j
        v_i = v[i]
        if v_i & bit_k == 0
            i += 1
        else
            v[i], v[j] = v[j], v_i
            j -= 1
        end
    end
    @assert i == j
    if k ≥ 2
        if v[i] & bit_k != 0
            i -= 1
        else
            j += 1
        end
        radixsort!(v, lo, i, k - 1)
        radixsort!(v, j, hi, k - 1)
    end
    return v
end
