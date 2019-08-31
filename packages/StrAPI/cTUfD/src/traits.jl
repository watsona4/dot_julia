# Copyright 2017-2018 Gandalf Software, Inc. (Scott Paul Jones)
# Licensed under MIT License, see LICENSE.md

# These use the "Holy Trait Trick", which was created by @timholy (Tim Holy),
# which was made possible by the type system in Julia from @jeff.bezanson (Jeff Bezanson).

# One is proud to stand on the shoulders of such people!

## Traits for string and character types ##

"""
    ValidatedStyle(A)
    ValidatedStyle(typeof(A))

`ValidatedStyle` specifies the whether a string or character type is always valid or not
When you define a new `AbstractString` or `AbstractChar` type, you can choose to implement it
as always validated, or validation state unknown.

    StrAPI.ValidatedStyle(::Type{<:MyCharType}) = StrAPI.AlwaysValid()

The default is `UnknownValidity`
"""
abstract type ValidatedStyle end
struct AlwaysValid     <: ValidatedStyle end
struct UnknownValidity <: ValidatedStyle end

# single or multiple codeunits per codepoint

"""
    EncodingStyle(A)
    EncodingStyle(typeof(A))

`EncodingStyle` specifies the whether a character set encoding uses one or multiple codeunits to
encode a single codepoint.
When you define a new `AbstractString` type, you can choose to implement it with either
single or multi-codeunit indexing.

    StrAPI.EncodingStyle(::Type{MyCharSetEncoding}) = StrAPI.MultiCodeUnitEncoding()

The default is `SingleCodeUnitEncoding()`
"""
abstract type EncodingStyle end

struct SingleCodeUnitEncoding <: EncodingStyle end
struct MultiCodeUnitEncoding  <: EncodingStyle end

# Type of character set

"""
    CharSetStyle(A)
    CharSetStyle(typeof(A))

`CharSetStyle` specifies the information about the character set used by the string or
characters.
When you define a new `AbstractString` or `AbstractChar` type,
you can choose to implement it with

    StrAPI.CharSetStyle(::Type{<:MyString}) = StrAPI.CharSetISOCompat()

The default is `CharSetUnicode()`
"""
abstract type CharSetStyle end

"""Codepoints are not in Unicode compatible order"""
struct CharSetOther         <: CharSetStyle end
"""Characters 0-0x7f same as ASCII"""
struct CharSetASCIICompat   <: CharSetStyle end
"""Characters 0-0x9f follows ISO 8859"""
struct CharSetISOCompat     <: CharSetStyle end
"""Characters 0-0xd7ff, 0xe000-0xffff follow Unicode BMP"""
struct CharSetBMP           <: CharSetStyle end
"""Full Unicode character set, no additions"""
struct CharSetUnicode       <: CharSetStyle end
"""Unicode character set, plus encodings of invalid characters"""
struct CharSetUnicodePlus   <: CharSetStyle end
"""8-bit Binary string, not text"""
struct CharSetBinary        <: CharSetStyle end
"""Raw bytes, words, or character string, unknown encoding/character set"""
struct CharSetUnknown       <: CharSetStyle end

# Comparison traits

"""
    CompareStyle(Union{A, typeof(A)}, Union{B, typeof(B)})

`CompareStyle` specifies how to compare two strings with character set encodings A and B

    StrAPI.CompareStyle(::Type{<:MyString}, ::Type{String}) = StrAPI.ByteCompare()

The default is `CodePointCompare`
"""
abstract type CompareStyle end

struct NoCompare        <: CompareStyle end # For equality checks, can't be equal
struct ByteCompare      <: CompareStyle end # Compare bytewise
struct ASCIICompare     <: CompareStyle end # Compare bytewise for ASCII subset, else codepoint
struct WordCompare      <: CompareStyle end # Compare first not equal word with <
struct UTF16Compare     <: CompareStyle end # Compare first not equal word adjusting > 0xd7ff
struct WidenCompare     <: CompareStyle end # Narrower can be simply widened for comparisons
struct CodePointCompare <: CompareStyle end # Compare CodePoints

promote_rule(::Type{NoCompare},    ::Type{<:CompareStyle})   = NoCompare
promote_rule(::Type{ByteCompare},  ::Type{CodePointCompare}) = ByteCompare
promote_rule(::Type{WordCompare},  ::Type{CodePointCompare}) = WordCompare
promote_rule(::Type{UTF16Compare}, ::Type{CodePointCompare}) = UTF16Compare
promote_rule(::Type{ASCIICompare}, ::Type{CodePointCompare}) = ASCIICompare
promote_rule(::Type{WidenCompare}, ::Type{CodePointCompare}) = WidenCompare

"""Determine if a string has multiple codeunit encoding"""
function is_multi end

is_multi(::Type{T}) where {T<:AbstractString} = EncodingStyle(T) === MultiCodeUnitEncoding()
is_multi(::T) where {T<:AbstractString} = is_multi(T)

@api develop AlwaysValid, UnknownValidity,
             SingleCodeUnitEncoding, MultiCodeUnitEncoding,
             CharSetOther, CharSetBinary, CharSetASCIICompat, CharSetISOCompat,
             CharSetBMP, CharSetUnicode, CharSetUnicodePlus, CharSetUnknown,
             NoCompare, CodePointCompare, ByteCompare, ASCIICompare, WordCompare,
             UTF16Compare, WidenCompare

@api develop! ValidatedStyle, EncodingStyle, CharSetStyle, CompareStyle, is_multi
