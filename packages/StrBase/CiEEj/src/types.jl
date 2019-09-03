#=
Basic types for strings

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#
const STR_KEEP_NUL    = true  # keep nul byte placed by String

# Note: this is still in transition to expressing character set, encoding
# and optional cached info for hashes, UTF-8/UTF-16 encodings, subsets, etc.
# via more type parameters

struct Str{T,SubStr,Cache,Hash} <: AbstractString
    data::String
    substr::SubStr
    cache::Cache
    hash::Hash

    (::Type{Str})(::Type{T}, v::String, s::S, c::C, h::H) where {T<:CSE,S,C,H} =
        new{T,S,C,H}(v,s,c,h)
end

_msk16(v, m) = (v%UInt16) & m
_msk32(v, m) = (v%UInt32) & m

_mskup16(v, m, s) = _msk16(v, m) << s
_mskup32(v, m, s) = _msk32(v, m) << s
_mskdn16(v, m, s) = _msk16(v, m) >>> s
_mskdn32(v, m, s) = _msk32(v, m) >>> s

(::Type{Str})(::Type{C}, v::String) where {C<:CSE} = Str(C, v, nothing, nothing, nothing)
(::Type{Str})(::Type{C}, v::Str) where {C<:CSE} = Str(C, v.data, nothing, nothing, nothing)

# Handle change from endof -> lastindex
@static if !isdefined(Base, :lastindex)
    lastindex(str::AbstractString) = Base.endof(str)
    lastindex(arr::AbstractArray) = Base.endof(arr)
    Base.endof(str::Str) = lastindex(str)
end
@static if !isdefined(Base, :firstindex)
    firstindex(str::AbstractString) = 1
    # AbstractVector might be an OffsetArray
    firstindex(str::Vector) = 1
end

# Definition of built-in Str types

const empty_string = ""

for lst in cse_info
    nam, typ = lst
    str = String(nam)
    sym = symstr(nam, "Str")
    cse = symstr(nam, "CSE")
    @eval const $sym = Str{$cse, Nothing, Nothing, Nothing}
    @eval (::Type{$sym})(v::Vector{UInt8}) = convert($sym, v)
    @eval show(io::IO, ::Type{$sym}) = print(io, $(quotesym(sym)))
    low = lowercase(str)
    if str[1] == '_'
        @eval empty_str(::Type{$cse}) = $(symstr("empty", low))
        @eval @api develop $sym
    else
        emp = symstr("empty_", low)
        @eval const $emp = Str($cse, empty_string)
        @eval empty_str(::Type{$cse}) = $emp
        @eval @api public $sym
    end
    @eval convert(::Type{$sym}, str::$sym) = str
end
empty_str(::Type{<:Str{C}}) where {C<:CSE} = empty_str(C)
empty_str(::Type{String}) = empty_string

typemin(::Type{T}) where {T<:Str} = empty_str(T)
typemin(::T) where {T<:Str} = empty_str(T)

"""Union type for fast dispatching"""
const UniStr = Union{ASCIIStr, _LatinStr, _UCS2Str, _UTF32Str}
show(io::IO, ::Type{UniStr}) = print(io, :UniStr)

# Display BinaryCSE as if String
show(io::IO, str::T) where {T<:Str{BinaryCSE}} = show(io, str.data)
show(io::IO, str::SubString{T}) where {T<:Str{BinaryCSE}} =
    @inbounds show(io, SubString(str.string.data, str.offset+1, str.offset+lastindex(str)))

_allocate(len) = Base._string_n((len+STR_KEEP_NUL-1)%Csize_t)

function _allocate(::Type{T}, len) where {T <: CodeUnitTypes}
    buf = _allocate((len+STR_KEEP_NUL-1) * sizeof(T))
    buf, reinterpret(Ptr{T}, pointer(buf))
end

# Various useful groups of character set types

const MS_UTF8     = MaybeSub{<:Str{UTF8CSE}}
const MS_UTF16    = MaybeSub{<:Str{UTF16CSE}}
const MS_UTF32    = MaybeSub{<:Str{UTF32CSE}}
const MS_SubUTF32 = MaybeSub{<:Str{_UTF32CSE}}
const MS_Latin    = MaybeSub{<:Str{<:Latin_CSEs}}
const MS_ByteStr  = MaybeSub{<:Str{<:Binary_CSEs}}
const MS_RawUTF8  = MaybeSub{<:Union{String,Str{RawUTF8CSE}}}

_wrap_substr(::Type{<:Any}, str) = str
_wrap_substr(::Type{SubString}, str) = SubString(str, 1)
_empty_sub(::Type{T}, ::Type{C}) where {T,C} = _wrap_substr(T, empty_str(C))

## Get the character set / encoding used by a string type
cse(::Type{<:Str{C}}) where {C<:CSE} = C

# Promotion rules for characters

promote_rule(::Type{T}, ::Type{T}) where {T<:Str} = T

promote_rule(::Type{String}, ::Type{<:Str}) = String

promote_rule(::Type{<:Str{S}}, ::Type{<:Str{T}}) where {S,T} =
    (P = promote_rule(S,T)) === Union{} ? Union{} : Str{P}

sizeof(s::Str) = sizeof(s.data) + 1 - STR_KEEP_NUL

"""Codeunits of string as a Vector"""
_data(s::Vector{UInt8}) = s
_data(s::String)        = s
_data(s::Str{<:Byte_CSEs}) = unsafe_wrap(Vector{UInt8}, s.data)

"""Pointer to codeunits of string"""
pointer(s::Str{<:Byte_CSEs}) = pointer(s.data)
pointer(s::Str{<:Word_CSEs}) = reinterpret(Ptr{UInt16}, pointer(s.data))
pointer(s::Str{<:Quad_CSEs}) = reinterpret(Ptr{UInt32}, pointer(s.data))

const CHUNKSZ = sizeof(UInt64) # used for fast processing of strings
const CHUNKMSK = (CHUNKSZ-1)%UInt64

_pnt64(s::Union{String,Vector{UInt8}}) = reinterpret(Ptr{UInt64}, pointer(s))
_pnt64(s::Str) = reinterpret(Ptr{UInt64}, pointer(s.data))

"""Length of string in codeunits"""
ncodeunits(s::Str)              = sizeof(s)
ncodeunits(s::Str{<:Word_CSEs}) = sizeof(s) >>> 1
ncodeunits(s::Str{<:Quad_CSEs}) = sizeof(s) >>> 2

# For convenience
@inline _calcpnt(str, siz) = (pnt = _pnt64(str) - CHUNKSZ;  (pnt, pnt + siz))

@inline _mask_bytes(n) = ((1%UInt) << ((n & CHUNKMSK) << 3)) - 0x1

# Support for SubString of Str

Base.SubString(str::Str{C}) where {C<:SubSet_CSEs} =
    SubString(Str(basecse(C), str))
Base.SubString(str::Str{C}, off::Int) where {C<:SubSet_CSEs} =
    SubString(Str(basecse(C), str), off)
Base.SubString(str::Str{C}, off::Int, fin::Int) where {C<:SubSet_CSEs} =
    SubString(Str(basecse(C), str), off, fin)

# pointer conversions of ASCII/UTF8/UTF16/UTF32 strings:
pointer(str::Str, pos::Integer) = bytoff(pointer(str), pos - 1)

# pointer conversions of SubString of ASCII/UTF8/UTF16/UTF32:
pointer(x::SubString{<:Str}) = bytoff(pointer(x.string), x.offset)
pointer(x::SubString{<:Str}, pos::Integer) = bytoff(pointer(x.string), x.offset + pos - 1)
