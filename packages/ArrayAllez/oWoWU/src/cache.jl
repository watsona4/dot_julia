
export Array_, similar_, copy_

struct CacheKey{T}
    name::Symbol
    l::Int
    c::Int

    CacheKey(n::Symbol, A::AT, sz::NTuple{M,Int} = size(A)) where AT <: AbstractArray{T,M} where {T,M} =
        new{AT}(n, prod(sz), checksum(sz))
    CacheKey(n::Symbol, ::Val{T}, sz::NTuple{M,Int}) where {T,M} = new{Array{T,M}}(n, prod(sz), checksum(sz))
end

checksum(size::NTuple{N,Int}) where N = sum(ntuple(i -> size[i] * i^2, Val(N)))

using LRUCache

const cache = LRU{CacheKey, AbstractArray}(;maxsize = 100) # very crude: fixed size, for now

# function Base.getindex(lru::LRU, key::CacheKey{AT}) where AT
#     node = lru.ht[key]
#     LRUCache.move_to_front!(lru.q, node)
#     return node.v::AT # to improve type stability?
# end

"""
    similar_(name, A)     ≈ similar(A)
    Array_{T}(name, size) ≈ Array{T}(undef, size)
New arrays for intermediate results, drawn from an LRU cache when `length(A) >= 2000`.
The cache's key uses `name::Symbol` as well as type & size to ensure different uses don't collide.

    copy_(name, A) = copyto!(similar_(name, A), A)
Just like that.
"""
similar_(A::AbstractArray) = similar_(:array_, A)

function similar_(name::Symbol, A::TA)::TA where TA<:AbstractArray
    if length(A) < 2000
        similar(A)
    else
        get(cache, CacheKey(name, A)) do
            similar(A)
        end
    end
end

struct Array_{T} end

@doc @doc(similar_)
Array_(any...) = Array_{Float64}(any...)

Array_{T}(sz::Vararg{Int}) where {T} =  Array_{T}(:Array_, sz)

Array_{T}(name::Symbol, sz::Vararg{Int}) where {T} =  Array_{T}(name, sz)

Array_{T}(sz::Tuple) where {T} = Array{T}(:Array_, sz)

function Array_{T}(name::Symbol, sz::NTuple{N,Int}) where {T,N}
    key = CacheKey(name, Val(T), sz)
    if prod(sz) < 2000
        Array{T}(undef, sz);
    else
        get(cache, key) do
            Array{T, N}(undef, sz)
        end
    end
end

@doc @doc(similar_)
copy_(A::AbstractArray) = copy_(:copy_, A)

copy_(name::Symbol, A::AbstractArray) = copyto!(similar_(name, A), A)

