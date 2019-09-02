# internal data for packed integers
struct Buffer{w,T<:Unsigned}
    data::Vector{T}
    function Buffer{w,T}(len::Integer, mmap::Bool=false) where {w,T<:Unsigned}
        @assert w ≤ bitsof(T)
        buflen = cld(len * w, bitsof(T))
        data = mmap ? Mmap.mmap(Vector{T}, buflen) : Vector{T}(undef, buflen)
        return new(data)
    end
end

bitsof(::Type{T}) where {T} = sizeof(T) * 8

function Base.resize!(buffer::Buffer{w,T}, len::Integer) where {w,T}
    buflen = cld(len * w, bitsof(T))
    resize!(buffer.data, buflen)
    return buffer
end

@inline function mask(::Type{T}, w) where {T}
    ~T(0) >> (bitsof(T) - w)
end

@inline function get_chunk_id(::Buffer{w,UInt8}, i::Integer) where {w}
    j = Int(i - 1) * w
    return (j >> 3) + 1, j & 0b000111
end

@inline function get_chunk_id(::Buffer{w,UInt16}, i::Integer) where {w}
    j = Int(i - 1) * w
    return (j >> 4) + 1, j & 0b001111
end

@inline function get_chunk_id(::Buffer{w,UInt32}, i::Integer) where {w}
    j = Int(i - 1) * w
    return (j >> 5) + 1, j & 0b011111
end

@inline function get_chunk_id(::Buffer{w,UInt64}, i::Integer) where {w}
    j = Int(i - 1) * w
    return (j >> 6) + 1, j & 0b111111
end


@inline function Base.getindex(buf::Buffer{w,T}, i::Integer) where {w,T}
    k, r = get_chunk_id(buf, i)
    W = bitsof(T)
    @inbounds begin
        a = buf.data[k] >> r
        if r + w ≤ W
            return a & mask(T, w)
        else
            b = buf.data[k+1] & mask(T, (w + r) - W)
            return a | (b << (W - r))
        end
    end
end

# these width values don't cross a boundary, therefore branching can be safely removed
for w in [1, 2, 4, 8, 16, 32, 64]
    @eval begin
        @inline function Base.getindex(buf::Buffer{$w,T}, i::Integer) where {T}
            k, r = get_chunk_id(buf, i)
            @inbounds return (buf.data[k] >> r) & mask(T, $w)
        end
    end
end

# https://graphics.stanford.edu/~seander/bithacks.html#MaskedMerge
@inline mergebits(a, b, mask) = a ⊻ ((a ⊻ b) & mask)

@inline function Base.setindex!(buf::Buffer{w,T}, x::T, i::Integer) where {w,T}
    k, r = get_chunk_id(buf, i)
    W = bitsof(T)
    @inbounds begin
        a = buf.data[k]
        b = x << r
        buf.data[k] = mergebits(a, b, mask(T, w) << r)
        if r + w > W
            a = buf.data[k+1]
            b = x >> (W - r)
            buf.data[k+1] = mergebits(a, b, mask(T, (w + r) - W))
        end
    end
    return
end

for w in [1, 2, 4, 8, 16, 32, 64]
    @eval begin
        @inline function Base.setindex!(buf::Buffer{$w,T}, x::T, i::Integer) where {T}
            k, r = get_chunk_id(buf, i)
            @inbounds begin
                a = buf.data[k]
                b = x << r
                buf.data[k] = mergebits(a, b, mask(T, $w) << r)
            end
            return
        end
    end
end

function Base.fill!(buf::Buffer{w,T}, x::T) where {w,T}
    x &= mask(T, w)
    W = bitsof(T)
    cycle = div(lcm(w, W), W)
    r = 0
    for j in 1:cycle
        chunk = T(0)
        if r < 0
            chunk |= (x >> (w + r)) << (W + r)
        end
        r += W
        while r > 0
            chunk >>= min(w, r)
            chunk  |= x << (W - min(w, r))
            r -= w
        end
        @inbounds for i in j:cycle:endof(buf.data)
            buf.data[i] = chunk
        end
    end
    return buf
end

for w in [1, 2, 4, 8, 16, 32, 64]
    @eval begin
        function Base.fill!(buf::Buffer{$w,T}, x::T) where {T}
            chunk = T(0)
            x &= mask(T, $w)
            for _ in 1:div(bitsof(T), $w)
                chunk = chunk << $w | x
            end
            fill!(buf.data, chunk)
            return buf
        end
    end
end

function fill0!(buf::Buffer{w,T}) where {w,T}
    fill!(buf.data, T(0))
    return buf
end

function fill1!(buf::Buffer{w,T}) where {w,T}
    fill!(buf.data, ~T(0))
    return buf
end
