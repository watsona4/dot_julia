# Copyright 2017-2018 Gandalf Software, Inc. (Scott Paul Jones)
# Licensed under MIT License, see LICENSE.md

ValidatedStyle(::Type{<:AbstractString}) = UnknownValidity()
ValidatedStyle(::Type{<:Str}) = AlwaysValid()

ValidatedStyle(A::T) where {T<:Union{AbsChar,AbstractString}} = ValidatedStyle(T)

CharSetStyle(::Type{<:Str{C}}) where {C<:CSE} = CharSetStyle(C)

# Different character sets
is_valid(::Type{Str{<:CSE{CS1}}}, str::T) where {T<:Str{<:CSE{CS2}},CS1} where {CS2} =
    _isvalid(ValidatedStyle(T), CS1, CS2, str)

# Same character set
is_valid(::Type{Str{<:CSE{CS}}}, str::T) where {T<:Str{<:CSE{CS}}} where {CS} =
    _isvalid(ValidatedStyle(T), str)

_isvalid(::UnknownValidity, str::T) where {T<:Str} = _isvalid(T, pointer(str), ncodeunits(str))

is_valid(::Type{T}, str::T) where {T<:Str}       = _isvalid(ValidatedStyle(T), str)
is_valid(str::T) where {T<:Str}       = _isvalid(ValidatedStyle(T), str)

# For now, there is only support for immutable `Str`s, when mutable `Str`s are added.

"""
    MutableStyle(A)
    MutableStyle(typeof(A))

`MutableStyle` specifies the whether a string type is mutable or not

    MutableStyle(::Type{<:MyString}) = MutableStr()

The default is `ImmutableStr`
"""
abstract type MutableStyle end
struct ImmutableStr <: MutableStyle end
struct MutableStr   <: MutableStyle end

MutableStyle(A::AbstractString) = MutableStyle(typeof(A))

MutableStyle(A::Str) = ImmutableStr()

_ismutable(::ImmutableStr, str::Type{T}) where {T<:Str} = false
_ismutable(::MutableStr, str::Type{T}) where {T<:Str} = true
is_mutable(::Type{T}) where {T<:Str} = _ismutable(MutableStyle(T))

isimmutable(str::T) where {T<:Str} = !is_mutable(T)

"""
    CanContain(Union{A, typeof(A)}, Union{B, typeof(B)})

`CanContainStyle` specifies whether the first string can contain a substring of the second type,
    and if so, what is the most efficient method of comparison

    CanContain(::Type{<:MyString}, ::Type{String}) = ByteCompare()

Returns an instance of type `CompareStyle`, default `CodePointCompare`
"""
CanContain(::Type{<:CSE}, ::Type{<:CSE}) = CodePointCompare()

CanContain(::Type{C}, ::Type{C}) where {C<:CSE} = ByteCompare()

CanContain(::Type{<:Binary_CSEs}, ::Type{<:Union{_UCS2CSE,_UTF32CSE}}) =
    NoCompare()
CanContain(::Type{<:Binary_CSEs}, ::Type{<:Byte_CSEs}) =
    ByteCompare()
CanContain(::Type{<:Binary_CSEs}, ::Type{<:Union{Word_CSEs, Quad_CSEs}}) =
    WidenCompare()

CanContain(::Type{ASCIICSE}, ::Type{<:SubSet_CSEs}) =
    NoCompare()
CanContain(::Type{ASCIICSE}, ::Type{<:Union{Binary_CSEs, LatinCSE, UTF8_CSEs}}) =
    ByteCompare()
CanContain(::Type{ASCIICSE}, ::Type{<:Union{Word_CSEs, Quad_CSEs}}) =
    WidenCompare()

CanContain(::Type{<:Latin_CSEs}, ::Type{<:Union{_UCS2CSE,_UTF32CSE}}) =
    NoCompare()
CanContain(::Type{<:Latin_CSEs}, ::Type{<:Union{Binary_CSEs,ASCIICSE,Latin_CSEs}}) =
    ByteCompare()
CanContain(::Type{<:Latin_CSEs}, ::Type{<:UTF8_CSEs}) =
    ASCIICompare()
CanContain(::Type{<:Latin_CSEs}, ::Type{<:Union{Word_CSEs, Quad_CSEs}}) =
    WidenCompare()

CanContain(::Type{<:UTF8_CSEs}, ::Type{<:Union{ASCIICSE,Binary_CSEs}}) =
    ByteCompare()
CanContain(::Type{<:UTF8_CSEs}, ::Type{<:Latin_CSEs}) =
    ASCIICompare()

CanContain(::Type{<:Union{Text2CSE,UCS2CSE}}, ::Type{_UTF32CSE}) =
    NoCompare()
CanContain(::Type{<:Union{Text2CSE,UCS2_CSEs}}, ::Type{<:Word_CSEs}) =
    ByteCompare()
CanContain(::Type{<:Union{Text2CSE,UCS2_CSEs}},
           ::Type{<:Union{ASCIICSE, Binary_CSEs, Latin_CSEs, Quad_CSEs}}) =
    WidenCompare()

CanContain(::Type{UTF16CSE}, ::Type{<:Union{ASCIICSE,Binary_CSEs,Latin_CSEs}}) =
    WidenCompare()
CanContain(::Type{UTF16CSE}, ::Type{<:Union{Text2CSE, UCS2_CSEs}}) =
    ByteCompare()

CanContain(::Type{<:Quad_CSEs}, ::Type{<:Quad_CSEs}) =
    ByteCompare()
CanContain(::Type{<:Quad_CSEs},
           ::Type{<:Union{Binary_CSEs,ASCIICSE,Latin_CSEs,Text2CSE,UCS2_CSEs}}) =
    WidenCompare()

CanContain(::Type{S}, ::Type{T}) where {S<:AbstractString, T<:AbstractString} =
    CanContain(cse(S), cse(T))
CanContain(::Type{T}, ::Type{T}) where {T<:AbstractString} = ByteCompare()

CanContain(A::AbstractString, B::AbstractString) = CanContain(typeof(A), typeof(B))

"""
    EqualsStyle(Union{A, typeof(A)}, Union{B, typeof(B)})

`EqualsStyle` specifies whether the first string can equal a substring of the second type,
    and if so, what is the most efficient method of comparison

This is determined by the CanContain trait
Returns an instance of type `CompareStyle`, default `CodePointCompare`
"""
EqualsStyle(::Type{S}, ::Type{T}) where {S<:CSE,T<:CSE} =
    Base.promote_typeof(CanContain(S, T), CanContain(T, S))()
EqualsStyle(::Type{T}, ::Type{T}) where {T<:CSE} = ByteCompare()

EqualsStyle(::Type{S}, ::Type{T}) where {S<:AbstractString, T<:AbstractString} =
    EqualsStyle(cse(S), cse(T))
EqualsStyle(::Type{T}, ::Type{T}) where {T<:AbstractString} = ByteCompare()

EqualsStyle(A::AbstractString, B::AbstractString) =  EqualsStyle(typeof(A), typeof(B))
