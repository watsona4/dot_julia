
struct BlockArray{T,N,M<:AbstractArray{T,N},P,NP,I} <: AbstractArray{T,N}
    A::M
    parts::NamedTuple{P,NTuple{NP,I}}
end
function BlockArray(A::AbstractMatrix,lengths::NTuple{N,Int},names::NTuple{N,Symbol}) where {N,T}
    parts = create_partition2(lengths,names)
    BlockArray(A,parts)
end
function BlockArray(A::AbstractVector,lengths::NTuple{N,Int},names::NTuple{N,Symbol}) where {N,T}
    parts = create_partition(lengths,Tuple(names))
    BlockArray(A,parts)
end
BlockArray(A::AbstractArray,lengths::Vector{Int},names::Vector{Symbol}) = BlockArray(A,Tuple(lengths),Tuple(names))
BlockVector{T,M} = BlockArray{T,1,M}
BlockMatrix{T,M} = BlockArray{T,2,M}

size(A::BlockArray) = size(A.A)
getindex(A::BlockArray, i::Int) = getindex(A.A, i)
getindex(A::BlockArray, I::Vararg{Int, 2}) where N = A.A[I[1],I[2]]
getindex(A::BlockArray, I...) = getindex(A.A, I...)
setindex!(A::BlockArray, I...) = setindex!(A.A, I...)
setindex!(A::BlockArray, v, i::Int) = setindex!(A.A, v, i)
setindex!(A::BlockArray, v, I::Vararg{Int, N}) where N = A.A[I[1],I[2]] = v
IndexStyle(::BlockArray) = IndexCartesian()
length(A::BlockArray) = length(A.A)
Base.show(io::IO,A::BlockArray) = show(io::IO,A.A)
# Base.show(io::IO, T::MIME{Symbol("text/plain")}, X::BlockMatrix) = show(io, T::MIME"text/plain", X.A)
# display(A::Array{BlockArray,N} where N) = display(A.A)
+(A::BlockArray,B::Matrix) = A.A + B
+(B::Matrix,A::BlockArray) = A.A + B
getindex(A::BlockArray, p::Symbol) = view(A.A,getfield(A.parts,p)...)
getindex(A::BlockVector, p::Symbol) = view(A.A,getfield(A.parts,p))
Base.copy(A::BlockArray) = BlockArray(copy(A.A),A.parts)
function Base.getproperty(A::BlockArray{T,N}, p::Symbol) where {T,N}
    if p == :A || p == :parts
        getfield(A,p)
    else
        if N == 1
            return view(getfield(A,:A), getfield(getfield(A,:parts),p))
        else
            return view(getfield(A,:A), getfield(getfield(A,:parts),p)...)
        end
    end
end
