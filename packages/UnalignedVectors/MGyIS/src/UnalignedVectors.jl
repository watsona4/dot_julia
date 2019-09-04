__precompile__(true)

module UnalignedVectors

export UnalignedVector, MaybeUnalignedVector, unaligned_reinterpret

"""
    v = UnalignedVector{T}(a::Vector{UInt8})

Create a vector with element type `T` from a memory buffer of bytes
(`UInt8`). In contrast with `reinterpret`, this allows array creation
even if `a` does not have proper pointer alignment for `T`.
"""
struct UnalignedVector{T} <: AbstractArray{T,1}
    a::Vector{UInt8}
    len::Int

    function (::Type{UnalignedVector{T}})(a::Vector{UInt8}) where {T}
        len = length(a) ÷ sizeof(T)
        len*sizeof(T) == length(a) || throw(DimensionMismatch("length(a) should be a multiple of $(sizeof(T)), got $(length(a))"))
        new{T}(a, len)
    end
end

MaybeUnalignedVector{T} = Union{UnalignedVector{T},Vector{T}}

Base.IndexStyle(::Type{UnalignedVector{T}}) where {T} = IndexLinear()
@inline Base.length(a::UnalignedVector) = a.len
@inline Base.size(a::UnalignedVector) = (length(a),)

@inline function Base.getindex(a::UnalignedVector{T}, i::Int) where {T}
    @boundscheck checkbounds(a, i)
    unsafe_load(Ptr{T}(pointer(a.a)), i)
end
@inline function Base.setindex!(a::UnalignedVector{T}, val, i::Int) where {T}
    @boundscheck checkbounds(a, i)
    unsafe_store!(Ptr{T}(pointer(a.a)), val, i)
end

"""
    v = unaligned_reinterpret(T, a::Vector{UInt8})

Reinterprets `a` as an `UnalignedVector{T}`, unless `T == UInt8` in
which case `a` is returned.
"""
unaligned_reinterpret(::Type{T}, a::Vector{UInt8}) where {T} = UnalignedVector{T}(a)
unaligned_reinterpret(::Type{UInt8}, a::Vector{UInt8}) = a

function Base.reinterpret(::Type{T}, a::UnalignedVector, dims::Dims) where {T}
    reshape(unaligned_reinterpret(T, a.a), dims)
end
function Base.reinterpret(::Type{T}, a::Base.ReshapedArray{S,N,UnalignedVector{S}}, dims::Dims) where {T,S,N}
    reshape(unaligned_reinterpret(T, parent(a).a), dims)
end

end
