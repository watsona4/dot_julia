module StrFs

export StrF, @strf_str

using StaticArrays: SVector
using Parameters

import Base: sizeof, read, write, isless, cmp, ==, typemin, repeat, promote_rule, show,
    codeunit, hash, length

"""
    StrF{S}(::String)

A string of less than `S` bytes, represented using 0-terminated UTF-8.

# Internal representation

`bytes` are stored as an `SVector{S, UInt8}`, where `S` is the maximum number of bytes. They
are not validated to be conforming UTF-8. A terminating `0x00` follows **if and only if**
the string is shorter than `S` bytes.

This follows the `str#` ("sturfs") representation of [Stata](https://www.stata.com/help.cgi?dta).

# Operations

A comparisons, conversion, and a few operations are supported, but this is primarily meant
as a storage type. For complex manipulations, it is recommended that you convert to
`String`.
"""
struct StrF{S} <: AbstractString
    bytes::SVector{S,UInt8}
end

macro strf_str(str)
    StrF(str)
end

show(io::IO, str::StrF) = show(io, String(str))

# this implementation is a modified copy from base/hashing2.jl
function hash(str::StrF, h::UInt)
    h += Base.memhash_seed
    # note: use pointer(s) here (see #6058).
    ccall(Base.memhash, UInt, (Ptr{UInt8}, Csize_t, UInt32),
          Base.cconvert(Ptr{UInt8}, str.bytes), sizeof(str), h % UInt32) + h
end

promote_rule(::Type{String}, ::Type{StrF{S}}) where S = String

promote_rule(::Type{StrF{A}}, ::Type{StrF{B}}) where {A,B} = StrF{max(A,B)}

codeunit(::StrF{S}) where S = UInt8

function sizeof(str::StrF{S}) where S
    nul = findfirst(isequal(0x00), str.bytes)
    if nul ≡ nothing
        S
    else
        nul - 1
    end
end

read(io::IO, ::Type{StrF{S}}) where S = StrF{S}(read(io, SVector{S,UInt8}))

write(io::IO, str::StrF) = write(io, str.bytes)

String(str::StrF{S}) where S = String(str.bytes[1:sizeof(str)])

function StrF{S}(str::AbstractString) where S
    @assert codeunit(str) ≡ UInt8
    len = sizeof(str)
    len ≤ S || throw(InexactError(:StrF, StrF{S}, str))
    bytes = Vector{UInt8}(undef, S)
    copyto!(bytes, codeunits(str))
    if len < S
        bytes[len + 1] = UInt8(0)
    end
    StrF{S}(SVector{S,UInt8}(bytes))
end

function StrF{A}(str::StrF{B}) where {A,B}
    if A == B
        str
    elseif A > B
        StrF{A}(vcat(str.bytes, zeros(SVector{A - B,UInt8})))
    elseif sizeof(str) ≤ A
        StrF{A}(str.bytes[1:A])
    else
        throw(InexactError(:StrF, StrF{A}, str))
    end
end

function StrF(str::AbstractString)
    @assert codeunit(str) ≡ UInt8
    S = sizeof(str)
    StrF{S}(SVector{S,UInt8}(codeunits(str)))
end

function cmp(a::StrF{A}, b::StrF{B}) where {A, B}
    for (achar, bchar) in zip(a.bytes, b.bytes)
        (achar == bchar == 0x0) && return 0
        c = cmp(achar, bchar)
        c ≠ 0 && return c
    end
    A == B && return 0
    (A < B && b.bytes[A+1] ≠ 0) && return -1
    (A > B && a.bytes[B+1] ≠ 0) && return 1
    0
end

cmp(a::StrF, b::AbstractString) = cmp(a, StrF(b)) # TODO improve

cmp(a::AbstractString, b::StrF) = -cmp(b, a)

isless(a::StrF, b::StrF) = cmp(a, b) < 0

(==)(a::StrF, b::StrF) = cmp(a, b) == 0

typemin(::StrF{S}) where S = StrF(zeros(SVector{S}))

length(str::StrF) = length(String(str)) # TODO improve

function repeat(str::StrF{S}, ::Val{n}) where {S, n}
    @unpack bytes = str
    s = sizeof(str)
    vS = n * s
    v = Vector{UInt8}(undef, vS)
    offset = 1
    for _ in 1:n
        copyto!(v, offset, bytes, 1, s)
        offset += s
    end
    if offset < vS
        v[offset] = 0
    end
    StrF{S}(SVector{S}(v))
end

function Base.iterate(str::StrF, state = (String(str), ))
    # NOTE: iteration implemented by converting to a string, and using it as the first
    # element of the state. The second element is the state for the iterator of the latter.
    y = iterate(state...)
    y ≡ nothing && return y
    first(y), (first(state), last(y))
end

Base.IteratorSize(::Type{<:StrF}) = Base.IteratorSize(String)

Base.IteratorEltype(::Type{<:StrF}) = Base.IteratorEltype(String)

Base.eltype(::Type{<:StrF}) = Base.eltype(String)

end # module
