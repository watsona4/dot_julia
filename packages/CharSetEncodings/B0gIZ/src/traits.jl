# Copyright 2017-2018 Gandalf Software, Inc. (Scott Paul Jones)
# Licensed under MIT License, see LICENSE.md

EncodingStyle(::Type{<:Union{UTF8_CSEs,UTF16CSE}}) = MultiCodeUnitEncoding()
EncodingStyle(::Type{<:CSE}) = SingleCodeUnitEncoding()

EncodingStyle(v::AbstractString) = EncodingStyle(typeof(v))
EncodingStyle(::Type{T}) where {T<:AbstractString} = EncodingStyle(cse(T))
EncodingStyle(::Type{<:SubString{T}}) where {T<:AbstractString} = EncodingStyle(T)

################################################################################

CharSetStyle(::Type{<:CSE}) = CharSetUnicodePlus()
CharSetStyle(::Type{<:Union{Text1CSE, Text2CSE, Text4CSE}}) = CharSetUnknown()
CharSetStyle(::Type{BinaryCSE})    = CharSetBinary()
CharSetStyle(::Type{ASCIICSE})     = CharSetASCIICompat()
CharSetStyle(::Type{<:Latin_CSEs}) = CharSetISOCompat()
CharSetStyle(::Type{<:UCS2_CSEs})  = CharSetBMPCompat()

CharSetStyle(::Type{<:AbstractString}) = CharSetUnicodePlus()
CharSetStyle(::Type{<:AbstractChar})   = CharSetUnicode()
CharSetStyle(::Type{Char})      = CharSetUnicodePlus() # Encodes invalid characters also
CharSetStyle(::Type{UInt8})     = CharSetBinary()
CharSetStyle(::Type{UInt16})    = CharSetUnknown()
CharSetStyle(::Type{UInt32})    = CharSetUnknown()

CharSetStyle(::T) where {T<:AbstractString} = CharSetStyle(cse(T))
CharSetStyle(::T) where {T<:AbstractChar}   = CharSetStyle(T)

################################################################################

CompareStyle(::Type{<:CSE}, ::Type{<:CSE}) = CodePointCompare()

CompareStyle(::Type{C}, ::Type{C}) where {C<:CSE} =
    ByteCompare()
CompareStyle(::Type{C}, ::Type{C}) where {C<:Union{Word_CSEs,Quad_CSEs}} =
    WordCompare()

# This is important because of invalid sequences
CompareStyle(::Type{C}, ::Type{C}) where {C<:RawUTF8CSE} =
    CodePointCompare()


CompareStyle(::Type{UTF16CSE},    ::Type{UTF16CSE})    = UTF16Compare()
CompareStyle(::Type{UTF16CSE},    ::Type{<:UCS2_CSEs}) = UTF16Compare()
CompareStyle(::Type{<:UCS2_CSEs}, ::Type{UTF16CSE})    = UTF16Compare()

CompareStyle(::Type{ASCIICSE}, ::Type{<:Union{Binary_CSEs,Latin_CSEs,UTF8_CSEs}}) =
    ByteCompare()
CompareStyle(::Type{ASCIICSE}, ::Type{<:Union{Word_CSEs,Quad_CSEs}}) =
    WidenCompare()

CompareStyle(::Type{<:Latin_CSEs}, ::Type{<:Latin_CSEs}) =
    ByteCompare()
CompareStyle(::Type{<:Latin_CSEs}, ::Type{UTF8_CSEs}) =
    ASCIICompare()
CompareStyle(::Type{<:Latin_CSEs}, ::Type{<:Union{Word_CSEs,Quad_CSEs}}) =
    WidenCompare()

CompareStyle(::Type{<:UCS2_CSEs}, ::Type{<:Union{ASCIICSE,Binary_CSEs,Latin_CSEs,Quad_CSEs}}) =
    WidenCompare()
CompareStyle(::Type{<:UCS2_CSEs},  ::Type{<:UCS2_CSEs}) =
    WordCompare()

CompareStyle(::Type{<:UTF32_CSEs},
             ::Type{<:Union{ASCIICSE,Binary_CSEs,Latin_CSEs,Text2CSE,UCS2_CSEs}}) =
    WidenCompare()
CompareStyle(::Type{<:UTF32_CSEs},  ::Type{<:UTF32_CSEs}) =
    WordCompare()

CompareStyle(::Type{S}, ::Type{T}) where {S<:AbstractString, T<:AbstractString} =
    CompareStyle(cse(S), cse(T))
CompareStyle(::Type{T}, ::Type{T}) where {T<:AbstractString} = ByteCompare()

CompareStyle(A::AbstractString, B::AbstractString) = CompareStyle(typeof(A), typeof(B))
