# Character Set Encoding support
#
# Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
# Licensed under MIT License, see LICENSE.md

@api public CSE, "@cse"
@api public! basecse
@api develop cse_types

struct CSE{CS, ENC}  end

"""List of installed character set encodings"""
const cse_types = []

CSE(cs, e)  = CSE{CharSet(cs), Encoding(e)}()

macro cse(cs, e)
    :(CSE{CharSet{$(quotesym(cs)), $(quotesym(e))}()})
end

const _CSE{U} = Union{CharSet{U}, Encoding{U}} where {U}

print(io::IO, ::S) where {S<:_CSE{U}} where {U} = print(io, U)

show(io::IO, ::Type{CSE{CS,E}}) where {S,T,CS<:CharSet{S},E<:Encoding{T}} =
    print(io, "CSE{", string(S), ", ", string(T), "}")
print(io::IO, ::T) where {S,U,CS<:CharSet{S},E<:Encoding{U},T<:CSE{CS,E}} =
    (show(io, T); print(io, "()"))

# Definition of built-in CSEs (Character Set Encodings)

codeunit(::Type{<:CSE}) = UInt8
basecse(::Type{C}) where {C<:CSE} = C

for lst in cse_info
    nam, cu = lst
    cse = symstr(nam, "CSE")
    if length(lst) > 2
        csnam = symstr(lst[3], "CharSet")
        enc = cu === UInt8 ? :UTF8Encoding : :NativeUTF16
    else
        csnam = symstr(nam, "CharSet")
        enc = cu === UInt8 ? :Native1Byte : cu === UInt16 ? :Native2Byte : :Native4Byte
    end
    @eval const $(symstr(nam, "CSE")) = CSE{$csnam, $enc}
    @eval show(io::IO, ::Type{$cse}) = print(io, $(String(cse)))
    cu === UInt8 || (@eval codeunit(::Type{$cse}) = $cu)
    @eval push!(cse_types, $cse)
    if String(nam)[1] == '_'
        @eval basecse(::Type{$cse}) = $(symstr(String(nam)[2:end], "CSE"))
        @eval @api develop $cse
    else
        @eval @api public $cse
    end
end

# Various useful groups of character set types

# These should be done via traits
const Binary_CSEs   = Union{Text1CSE, BinaryCSE}
const Latin_CSEs    = Union{LatinCSE, _LatinCSE}
const UTF8_CSEs     = Union{UTF8CSE,  RawUTF8CSE}
const UCS2_CSEs     = Union{UCS2CSE,  _UCS2CSE}
const UTF32_CSEs    = Union{UTF32CSE, _UTF32CSE}
const SubSet_CSEs   = Union{_LatinCSE, _UCS2CSE, _UTF32CSE}

const Byte_CSEs     = Union{ASCIICSE, Binary_CSEs, Latin_CSEs, UTF8_CSEs} # 8-bit code units
const Word_CSEs     = Union{Text2CSE, UCS2CSE, _UCS2CSE, UTF16CSE} # 16-bit code units
const Quad_CSEs     = Union{Text4CSE, UTF32CSE, _UTF32CSE}         # 32-bit code units

@api develop Binary_CSEs, Latin_CSEs, UTF8_CSEs, UCS2_CSEs, UTF32_CSEs, SubSet_CSEs,
             Byte_CSEs, Word_CSEs, Quad_CSEs

cse(::Type{<:AbstractString}) = RawUTF8CSE     # allows invalid sequences
cse(::Type{<:SubString{T}}) where {T} = basecse(T)
cse(::T) where {T<:AbstractString} = cse(T)

basecse(::Type{T}) where {T<:AbstractString} = basecse(cse(T))
basecse(::T) where {T<:AbstractString} = basecse(cse(T))

# Get charset based on CSE
charset(::Type{<:CSE{CS}}) where {CS<:CharSet} = CS
charset(::Type{T}) where {T<:AbstractString} = charset(cse(T))
charset(::T) where {T<:AbstractString} = charset(cse(T))

# Get encoding based on CSE
encoding(::Type{<:CSE{CS,E}}) where {CS<:CharSet,E<:Encoding} = E

# Promotion rules for character set encodings

promote_rule(::Type{Text2CSE}, ::Type{Text1CSE}) = Text2CSE
promote_rule(::Type{Text4CSE}, ::Type{Text1CSE}) = Text4CSE
promote_rule(::Type{Text4CSE}, ::Type{Text2CSE}) = Text4CSE

promote_rule(::Type{T}, ::Type{ASCIICSE}) where {T<:CSE} = T
promote_rule(::Type{T}, ::Type{<:Latin_CSEs}
             ) where {T<:Union{UTF8CSE,UTF16CSE,UCS2_CSEs,UTF32_CSEs}} = T

promote_rule(::Type{T}, ::Type{_LatinCSE}) where {T<:Union{ASCIICSE,LatinCSE}} = LatinCSE

promote_rule(::Type{T}, ::Type{_UCS2CSE}) where {T<:Union{ASCIICSE,Latin_CSEs,UCS2CSE}} = UCS2CSE
promote_rule(::Type{T}, ::Type{_UTF32CSE}) where {T<:CSE} = UTF32CSE
promote_rule(::Type{T}, ::Type{UTF32CSE}) where {T<:UCS2_CSEs} = UTF32CSE
