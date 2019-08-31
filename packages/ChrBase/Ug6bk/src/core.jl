# ChrBase Chr type and core functions
# Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
# Licensed under MIT License, see LICENSE.md

struct Chr{CS<:CharSet,T<:CodeUnitTypes} <: AbstractChar
    v::T
    (::Type{Chr})(::Type{CS}, v::T) where {CS<:CharSet,T<:CodeUnitTypes} = new{CS,T}(v)
end

(::Type{<:Chr{CS,T}})(v::Number) where {CS<:CharSet,T<:CodeUnitTypes} = Chr(CS, T(v))

for lst in cse_info
    nam, typ = lst
    length(lst) < 3 || continue
    chrnam = symstr(nam, "Chr")
    if String(nam)[1] != '_'
        @eval @api public $chrnam
    elseif nam == :_Latin
        @api develop _LatinChr
    else
        continue
    end
    cs = symstr(nam, "CharSet")
    @eval const $chrnam = Chr{$cs, $typ}
    @eval show(io::IO, ::Type{$chrnam}) = print(io, $(quotesym(chrnam)))
    @eval codepoint_cse(::Type{$chrnam}) = $(symstr(nam,"CSE"))
    @eval (::Type{$chrnam})(v::Number) = Chr($cs, $typ(v))
end

codepoint(ch::Chr) = ch.v
basetype(::Type{<:Chr{CS,B}}) where {CS,B} = B
charset(::Type{<:Chr{CS,B}}) where {CS,B} = CS
typemin(::Type{T}) where {CS,B,T<:Chr{CS,B}} = Chr(CS, typemin(B))
typemax(::Type{T}) where {CS,B,T<:Chr{CS,B}} = Chr(CS, typemax(B))

const LatinChars   = Union{LatinChr, _LatinChr}
const ByteChars    = Union{ASCIIChr, LatinChr, _LatinChr, Text1Chr}
const WideChars    = Union{UCS2Chr, UTF32Chr}

codepoint_cse(::Type{Char}) = RawUTF8CSE

const AbsChar = @static isdefined(Base, :AbstractChar) ? AbstractChar : Union{Char, AbstractChar}

# Promotion rules for characters

promote_rule(::Type{T}, ::Type{T}) where {T<:Chr} = T

promote_rule(::Type{Char}, ::Type{<:Chr})   = Char

Base.need_full_hex(c::Chr) = is_hex_digit(c)
Base.escape_nul(c::Chr) = ('0' <= c <= '7') ? "\\x00" : "\\0"

bytoff(::Type{UInt8},  off) = off
bytoff(::Type{UInt16}, off) = off << 1
bytoff(::Type{UInt32}, off) = off << 2
chroff(::Type{UInt8},  off) = off
chroff(::Type{UInt16}, off) = off >>> 1
chroff(::Type{UInt32}, off) = off >>> 2

chrdiff(pnt::Ptr{T}, beg::Ptr{T}) where {T<:CodeUnitTypes} = Int(chroff(T, pnt - beg))

bytoff(pnt::Ptr{T}, off) where {T<:CodeUnitTypes} = pnt + bytoff(T, off)

typemax(::Type{ASCIIChr}) = ASCIIChr(0x7f)
typemax(::Type{UTF32Chr}) = UTF32Chr(0x10ffff)

basetype(::Type{Char})        = UInt32
basetype(::Type{T}) where {T<:CodeUnitTypes} = T

convert(::Type{T}, v::S) where {T<:Integer, S<:Chr} = convert(T, codepoint(v))::T
convert(::Type{T}, v::Signed) where {T<:Chr} =
    (v >= 0 && is_valid(T, v%Unsigned)) ? convert(T, v%Unsigned) : codepoint_error(T, v)
convert(::Type{T}, v::Unsigned) where {CS,B,T<:Chr{CS,B}} =
    is_valid(T, v) ? Chr(CS, v%B) : codepoint_error(T, v)
convert(::Type{Char}, v::T) where {T<:Chr} = convert(Char, codepoint(v))
convert(::Type{T}, v::Char) where {T<:Chr} = convert(T, codepoint(v))::T

rem(x::Number, ::Type{<:Chr{CS,B}}) where {CS,B} = Chr(CS, x%B)
rem(x::Char, ::Type{T}) where {T<:Chr}   = x%UInt32%T
rem(x::Chr, ::Type{T}) where {T<:Chr}    = (x.v)%T
rem(x::Chr, ::Type{T}) where {T<:Char}   = (x.v)%T
rem(x::Chr, ::Type{T}) where {T<:Number} = (x.v)%T

(::Type{S})(v::T) where {S<:Union{UInt32, Int, UInt}, T<:Chr} = codepoint(v)%S
(::Type{Char})(v::Chr) = Char(codepoint(v))
(::Type{T})(v::Char) where {T<:Chr} = T(codepoint(v))

eltype(::Type{T}) where {T<:Chr} = T
size(cp::Chr, dim) = convert(Int, dim) < 1 ? boundserr(cp, dim) : 1
getindex(cp::Chr, i::Integer) = i == 1 ? cp : boundserr(cp, i)
getindex(cp::Chr, I::Integer...) = all(x -> x == 1, I) ? cp : boundserr(cp, I)

_uni_rng(m) = 0x00000:ifelse(m < 0xd800, m, m-0x800)
codepoint_rng(::Type{T}) where {T<:Chr} = _uni_rng(typemax(T)%UInt32)
codepoint_rng(::Type{Char}) = _uni_rng(0x10ffff)
codepoint_rng(::Type{Text2Chr}) = 0%UInt16:typemax(UInt16)
codepoint_rng(::Type{Text4Chr}) = 0%UInt32:typemax(UInt32)

codepoint_adj(::Type{T}, ch) where {T} = ifelse(ch < 0xd800, ch, ch+0x800)%T
codepoint_adj(::Type{T}, ch) where {T<:Union{Text2Chr,Text4Chr}} = ch%T

# returns a random valid Unicode scalar value in the correct range for the type of character
@static if V6_COMPAT
    import Base.Random: rand!, rand, AbstractRNG
    rand(r::AbstractRNG, ::Type{T}) where {T<:Chr} =
        codepoint_adj(T, rand(r, codepoint_rng(T)))
    rand!(rng::AbstractRNG, A::AbstractArray, r::UnitRange{<:Chr}) =
        rand!(rng, A, Base.Random.RangeGenerator(r))
else
    import Random: rand!, rand, AbstractRNG, SamplerType
    
    rand(r::AbstractRNG, ::SamplerType{T}) where {T<:Chr} =
        codepoint_adj(T, rand(r, codepoint_rng(T)))
end

==(x::Chr, y::AbsChar) = codepoint(x) == codepoint(y)
==(x::AbsChar, y::Chr) = codepoint(x) == codepoint(y)
==(x::Chr, y::Chr)     = codepoint(x) == codepoint(y)

isless(x::Chr, y::AbsChar) = codepoint(x) < codepoint(y)
isless(x::AbsChar, y::Chr) = codepoint(x) < codepoint(y)
isless(x::Chr, y::Chr)     = codepoint(x) < codepoint(y)

# This is so that the hash is compatible with isless, but it's very inefficient
Base.hash(x::Chr, h::UInt) = hash(Char(x), h)

# Support functions for UTF-8 handling
@inline get_utf8_2(ch) =
    (0xc0 | ((ch >>> 6)%UInt8), 0x80 | ((ch & 0x3f)%UInt8))
@inline get_utf8_3(ch) =
    (0xe0 | ((ch >>> 12)%UInt8), 0x80 | ((ch >>> 6) & 0x3f)%UInt8, 0x80 | ((ch & 0x3f)%UInt8))
@inline get_utf8_4(ch) =
    (0xf0 | ((ch >>>  18)%UInt8), 0x80 | (((ch >>> 12) & 0x3f)%UInt8),
     0x80 | ((ch >>>  6) & 0x3f)%UInt8, 0x80 | ((ch & 0x3f)%UInt8))

# Little-endian output here
@inline get_utf8_16(ch) =
    (ch >>> 6) | (((ch & 0x3f)%UInt16)<<8) | 0x80c0
@inline get_utf8_32(ch) =
    ((ch & 0xc0000) >>> 18) | ((ch & 0x3f000) >>> 4) |
    ((ch & 0xfc0) << 10) | (ch & 0x3f)<<24 | 0x808080f0

utf_trail(c::UInt8) = (0xe5000000 >>> ((c & 0xf0) >> 3)) & 0x3

is_valid_continuation(c) = ((c & 0xc0) == 0x80)

# Support functions for UTF-16 handling
@inline get_utf16(ch) = (0xd7c0 + (ch >> 10))%UInt16, (0xdc00 + (ch & 0x3ff))%UInt16

@inline get_utf16_32(ch) =
    ((0xd7c0 + (ch >>> 10))%UInt16) << 6 | (0xdc00 + (ch & 0x3ff))%UInt32

is_surrogate_lead(c::Unsigned) = ((c & ~0x003ff) == 0xd800)
is_surrogate_trail(c::Unsigned) = ((c & ~0x003ff) == 0xdc00)
is_surrogate_codeunit(c::Unsigned) = ((c & ~0x007ff) == 0xd800)

function _isvalid end
function _isvalid_chr end
