struct DataValueArrowVector{J,T<:Arrow.ArrowVector{Union{J,Missing}}} <: AbstractVector{DataValue{J}}
    data::T
end

Base.size(A::DataValueArrowVector) = size(A.data)

@inline function Base.getindex(A::DataValueArrowVector{J,T}, i) where {J,T}
    @boundscheck checkbounds(A.data, i)
    @inbounds o = Arrow.unsafe_isnull(A.data, i) ? DataValue{J}() : DataValue{J}(Arrow.unsafe_getvalue(A.data, i))
    o    
end

@inline function Base.getindex(A::DataValueArrowVector{J,T}, i) where {J,T<:Arrow.DictEncoding{Union{Missing,J}}}
    @boundscheck checkbounds(A.data, i)
    @inbounds o = Arrow.unsafe_isnull(A.data, i) ? DataValue{J}() : DataValue{J}(A.data.pool[A.data.refs[i]+1])
    o    
end

Base.IndexStyle(::Type{<:DataValueArrowVector}) = IndexLinear()

Base.eltype(::Type{DataValueArrowVector{J,T}}) where {J,T} = DataValue{J}

struct MissingDataValueVector{J,T<:AbstractVector{DataValue{J}}} <: AbstractVector{Union{J,Missing}}
    data::T
end

Base.size(A::MissingDataValueVector) = size(A.data)

@inline function Base.getindex(A::MissingDataValueVector, i)
    @inbounds o = isna(A.data[i]) ? missing : get(A.data[i])
    o    
end

Base.IndexStyle(::Type{<:MissingDataValueVector}) = IndexLinear()

Base.eltype(::Type{MissingDataValueVector{J,T}}) where {J,T} = Union{J,Missing}
