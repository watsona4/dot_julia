# Copyright 2017-2018 Gandalf Software, Inc. (Scott Paul Jones)
# Licensed under MIT License, see LICENSE.md

## Set traits for character types ##

ValidatedStyle(::Type{<:AbstractChar}) = UnknownValidity()
@static isdefined(Base, :AbstractChar) || (ValidatedStyle(::Type{Char}) = UnknownValidity())
ValidatedStyle(::Type{<:Chr}) = AlwaysValid()

ValidatedStyle(A::T) where {T<:AbsChar} = ValidatedStyle(T)

CharSetStyle(::Type{ASCIIChr})  = CharSetASCIICompat()
CharSetStyle(::Type{LatinChr})  = CharSetISOCompat()
CharSetStyle(::Type{_LatinChr}) = CharSetISOCompat()
CharSetStyle(::Type{UCS2Chr})   = CharSetBMPCompat()

# must check range if CS1 is smaller than CS2, even if CS2 is valid for it's range
_isvalid(::ValidatedStyle, ::Type{ASCIICharSet}, ::Type{T}, val) where {T<:CharSet} =
    is_ascii(val)

(_isvalid(::ValidatedStyle, ::Type{LatinCharSet}, ::Type{T}, val)
 where {T<:Union{Text2CharSet, Text4CharSet, UCS2CharSet, UTF32CharSet}}) =
     is_latin(val)

(_isvalid(::ValidatedStyle, ::Type{_LatinCharSet}, ::Type{T}, val)
 where {T<:Union{Text2CharSet, Text4CharSet, UCS2CharSet, UTF32CharSet}}) =
     is_latin(val)

(_isvalid(::ValidatedStyle, ::Type{UCS2CharSet}, ::Type{T}, val)
 where {T<:Union{Text2CharSet, Text4CharSet, UTF32CharSet}}) =
     is_bmp(val)

_isvalid(::ValidatedStyle, ::Type{UTF32CharSet}, ::Type{<:CharSet}, val) =
    is_unicode(val)

# no checking needed for cases where it is a superset of T
(_isvalid(::AlwaysValid, ::Type{LatinCharSet}, ::Type{T}, val)
  where {T<:Union{Text1CharSet,ASCIICharSet,_LatinCharSet}}) = true

(_isvalid(::AlwaysValid, ::Type{UCS2CharSet}, ::Type{T}, val)
  where {T<:Union{Text1CharSet,ASCIICharSet,LatinCharSet,_LatinCharSet,_UCS2CharSet}}) = true

(_isvalid(::AlwaysValid, ::Type{UTF32CharSet}, ::Type{T}, val)
  where {T<:Union{Text1CharSet,ASCIICharSet,LatinCharSet,UCS2CharSet,_LatinCharSet,_UCS2CharSet,_UTF32CharSet}}) =
    true

# no subsets allowed for these
_isvalid(::AlwaysValid, ::Type{_LatinCharSet}, ::Type{ASCIICharSet}, val) = false
(_isvalid(::AlwaysValid, ::Type{_UCS2CharSet}, ::Type{T}, val)
  where {T<:Union{Text1CharSet,ASCIICharSet,LatinCharSet,_LatinCharSet}}) = false
(_isvalid(::AlwaysValid, ::Type{_UTF32CharSet}, ::Type{T}, val)
 where {T<:Union{Text1CharSet,Text2CharSet,ASCIICharSet,LatinCharSet,
                 UCS2CharSet,_LatinCharSet,_UCS2CharSet}}) = false

(_isvalid(::AlwaysValid, ::Type{S}, ::Type{<:CodeUnitTypes}, chr)
 where {S<:Union{Text1CharSet,Text2CharSet,Text4CharSet}}) =
     chr <= typemax(S)
 
_isvalid(::AlwaysValid, v) = true

# By default, check that it is valid Unicode codepoint
_isvalid(::UnknownValidity, v) = _isvalid(UnknownValidity(), UTF32CharSet, charset(v), v)

is_valid(::Type{T}, chr::T) where {T<:Chr} = _isvalid(ValidatedStyle(T), chr)
is_valid(chr::T) where {T<:Chr} = _isvalid(ValidatedStyle(T), chr)

# Different character set
function is_valid(::Type{S}, chr::T) where {S<:Chr, T<:Chr}
    CS = charset(S)
    CT = charset(T)
    CS == CT ? _isvalid(ValidatedStyle(T), chr) : _isvalid(ValidatedStyle(T), CS, CT, chr)
end

# Not totally sure how to get rid of some of these, they really should be handled
# by the compiler, using the ValidatedStyle trait along with the character sets

_isvalid_chr(::Type{ASCIICharSet},  v) = is_ascii(v)
_isvalid_chr(::Type{LatinCharSet},  v) = is_latin(v)
_isvalid_chr(::Type{UCS2CharSet},   v) = is_bmp(v)
_isvalid_chr(::Type{UTF32CharSet},  v) = is_unicode(v)
_isvalid_chr(::Type{_LatinCharSet}, v) = is_latin(v)
_isvalid_chr(::Type{_UCS2CharSet},  v) = is_bmp(v)
_isvalid_chr(::Type{_UTF32CharSet}, v) = is_unicode(v)
_isvalid_chr(::Type{Text1CharSet},  v) = v <= typemax(UInt8)
_isvalid_chr(::Type{Text2CharSet},  v) = v <= typemax(UInt16)
_isvalid_chr(::Type{Text4CharSet},  v) = v <= typemax(UInt32)
_isvalid_chr(::Type{BinaryCharSet}, v) = v <= typemax(UInt8)

# Not totally sure about this, base Char is rather funky in v0.7
_isvalid_chr(::Type{UniPlusCharSet}, v) = v <= typemax(UInt32)

is_valid(::Type{T}, v::Unsigned) where {T<:Chr} =
    _isvalid_chr(charset(T), v)
is_valid(::Type{T}, v::Signed) where {T<:Chr} =
    0 <= v <= typemax(UInt32) && _isvalid_chr(charset(T), v%UInt32)

is_valid(::Type{Char}, ch::Union{Text1Chr, ASCIIChr, LatinChars, UCS2Chr, UTF32Chr}) = true
is_valid(::Type{Char}, ch::Text2Chr) = is_bmp(ch)
is_valid(::Type{Char}, ch::Text4Chr) = is_unicode(ch)
is_valid(::Type{T},    ch::Char) where {T<:Chr} = Base.isvalid(ch) && is_valid(T, ch%UInt32)
