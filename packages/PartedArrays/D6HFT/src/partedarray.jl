


import Base: size, getindex, setindex!, length, IndexStyle, +, -, getfield

# Parted Array Type
struct PartedArray{T,N,M<:AbstractArray{T,N},P} <: AbstractArray{T,N}
    A::M
    parts::P
    function PartedArray(A::AbstractArray{T,N}, partition::P) where {T,N,I,P<:Dict{Symbol,I}}
        new{T,N,typeof(A),P}(A, partition)
    end
    function PartedArray(A::AbstractArray{T,N}, partition::P) where {T,N,P<:NamedTuple}
        new{T,N,typeof(A),P}(A, partition)
    end
end

PartedVector{T,P} = PartedArray{T,1,P}
PartedMatrix{T,P} = PartedArray{T,2,P}

# Constructors
function PartedVector(A::AbstractVector, lengths::NTuple{N,Int}, names::NTuple{N,Symbol}) where N
    part = Dict(zip(names, create_partition(lengths)))
    PartedArray(A, part)
end
PartedVector(A::AbstractVector, lengths::Vector{Int}, names::Vector{Symbol}) = PartedVector(A, Tuple(lengths), Tuple(names))
function PartedVector(A::AbstractVector, lengths::NTuple{N,Int}, ::Val{names}) where {N,names}
    part = NamedTuple{names}(create_partition(lengths))
    PartedArray(A, part)
end
function PartedVector(A::AbstractVector, part::NamedTuple)
    PartedArray(A, part)
end

function PartedMatrix(A::AbstractMatrix, lengths::NTuple{N,Int}, names::NTuple{N,Symbol}) where N
    part = create_partition2(lengths, lengths)
    names = combine_names(names, names)
    partition = Dict(zip(names, part))
    PartedArray(A, partition)
end
PartedMatrix(A::AbstractMatrix, lengths::Vector{Int}, names::Vector{Symbol}) = PartedVector(A, Tuple(lengths), Tuple(names))
function PartedMatrix(A::AbstractMatrix, lengths::NTuple{N,Int}, ::Val{names}) where {N,names}
    part = create_partition2(lengths, lengths)
    partition = NamedTuple{names}(part)
    PartedArray(A, partition)
end
function PartedMatrix(A::AbstractMatrix, part::NamedTuple)
    PartedArray(A, part)
end

# Basic Methods
size(A::PartedArray) = size(A.A)
getindex(A::PartedArray, i::Int) = getindex(A.A, i)
getindex(A::PartedArray, I::Vararg{Int,2}) = A.A[I[1], I[2]]
getindex(A::PartedArray, I...) = getindex(A.A, I...)
setindex(A::PartedArray, v, I...) = setindex(A.A, v, I...)
setindex!(A::PartedArray, v, i::Int) = setindex!(A.A, v, i)
setindex!(A::PartedArray, v, I::Vararg{Int, 2}) = A.A[I[1], I[2]] = v
IndexStyle(A::PartedArray) = IndexCartesian()
length(A::PartedArray) = length(A.A)
Base.keys(A::PartedArray) = keys(A.part)
Base.copy(A::PartedArray) = PartedArray(copy(A.A),A.parts)
Base.zero(A::PartedArray) = PartedArray(zero(A.A), A.parts)
+(A::PartedArray, B::AbstractArray) = PartedArray(A.A + B, A.parts)
+(B::AbstractArray, A::PartedArray) = PartedArray(B + A.A, A.parts)
+(A::PartedArray, B::PartedArray) = PartedArray(A.A + B.A, merge(A.parts, B.parts))
+(A::PartedArray, b::Real) = PartedArray(A.A .+ b, A.parts)
getindex(A::PartedArray, p::Symbol) = view(getfield(A,:A), getfield(A,:parts)[p]...)
getindex(A::PartedVector, p::Symbol) = view(getfield(A,:A), getfield(A,:parts)[p])
function Base.getproperty(A::PartedArray{T,N,I}, p::Symbol) where {T,N,I}
    if p == :A || p == :parts
        getfield(A,p)
    else
        A[p]
    end
end
