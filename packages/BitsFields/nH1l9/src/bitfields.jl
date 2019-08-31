struct BitFields{N,U} <: AbstractBitFields  # N BitField{U} fields
   bitfields::NTuple{N,BitField{U}}

   function BitFields(bitfields::Vararg{BitField{U}, N}) where {N,U}
       return new{N,U}(bitfields)
   end
end


Base.eltype(::Type{BitFields{N,U}}) where {N,U} = U
Base.eltype(x::BitFields{N,U}) where {N,U} = U

Base.length(x::BitFields{N,U}) where {N,U} = N

Base.lastindex(x::BitFields{N,U}) where {N,U} =
    lastindex(x.bitfields)

Base.getindex(x::BitFields{N,U}, idx::Int) where {N,U} =
    getindex(x.bitfields, idx)

Base.getindex(x::BitFields{N,U}, idxs::AbstractRange{Int}) where {N,U} =
    getindex(x.bitfields, idxs)

function Base.iterate(x::BitFields{N,U}) where {N,U<:UBits}
    if length(x) > 0
       x[1], 2
    else
       nothing
    end
end

function Base.iterate(x::BitFields{N,U}, state::Int) where {N,U<:UBits}
    if state > length(x)
       nothing
    else
       x[state], state+1
    end
end

Base.get(bitfields::BitFields{N,U}, bits::Ref{U}) where {N,U<:UBits} = [get(bitfield, bits) for bitfield in bitfields]
Base.get(bitfields::BitFields{N,U}, bits::U) where {N,U<:UBits} = [get(bitfield, bits) for bitfield in bitfields]


names(bitfields::BitFields{N,U}) where {N,U<:UBits} = ((name(bitfield) for bitfield in bitfields)...,)

function Base.NamedTuple(bitfields::BitFields{N,U}) where {N,U<:UBits}
   bitfieldnames  = names(bitfields)
   values = ((bitfields)...,)
   nt = NamedTuple{bitfieldnames,NTuple{N,BitField}}(values)
   return nt
end


"""
    valuesoffields

obtain values assigned to fields of a struct type (in field order)
<from NamedTupleTools>
"""
valuesoffields(x::T) where {T<:NamedTuple} =
    ((getfield(x, name) for name in fieldnames(T))...,)

Base.NamedTuple(x::NamedTuple{S,NTuple{N,BitField}}, z::Ref{T}) where {S,N,T} =
    NamedTuple{fieldnames(typeof(x))}(get.(valuesoffields(x), z[]))

Base.NamedTuple(x::NamedTuple{S,NTuple{N,BitField}}, z::ByRef{T}) where {S,N,T} =
    NamedTuple{fieldnames(typeof(x))}(get.(valuesoffields(x), z.ref[]))

function BitFields(bitfields::NamedTuple, nt::NamedTuple)
    z = ByRef(eltype(bitfields[1]))
    for (fld,val) in zip(bitfields, nt)
        set!(fld, val, z)
    end
    return z
end
