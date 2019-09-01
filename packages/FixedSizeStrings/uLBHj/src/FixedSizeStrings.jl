module FixedSizeStrings

export FixedSizeString

import Base: iterate, lastindex, getindex, sizeof, length, ncodeunits, codeunit, isvalid, read, write

struct FixedSizeString{N} <: AbstractString
    data::NTuple{N,UInt8}
    FixedSizeString{N}(itr) where {N} = new(NTuple{N,UInt8}(itr))
end

FixedSizeString(s::AbstractString) = FixedSizeString{length(s)}(s)

function iterate(s::FixedSizeString{N}, i::Int = 1) where N
    i > N && return nothing
    return (Char(s.data[i]), i+1)
end

lastindex(s::FixedSizeString{N}) where {N} = N

getindex(s::FixedSizeString, i::Int) = Char(s.data[i])

sizeof(s::FixedSizeString) = sizeof(s.data)

length(s::FixedSizeString) = length(s.data)

ncodeunits(s::FixedSizeString) = length(s.data)

codeunit(::FixedSizeString) = UInt8
codeunit(s::FixedSizeString, i::Integer) = s.data[i]

isvalid(s::FixedSizeString, i::Int) = checkbounds(Bool, s, i)

function read(io::IO, T::Type{FixedSizeString{N}}) where N
    return read!(io, Ref{T}())[]::T
end

function write(io::IO, s::FixedSizeString{N}) where N
    return write(io, Ref(s))
end

end
