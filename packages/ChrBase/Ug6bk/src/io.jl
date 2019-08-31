#=
IO functions for Chr types

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#
@inline _write_utf8_2(io, ch) = write(io, get_utf8_2(ch)...)
@inline _write_utf8_3(io, ch) = write(io, get_utf8_3(ch)...)
@inline _write_utf8_4(io, ch) = write(io, get_utf8_4(ch)...)

@inline _write_ucs2(io, ch) =
    ch <= 0x7f ? write(io, ch%UInt8) : ch <= 0x7ff ? _write_utf8_2(io, ch) : _write_utf8_3(io, ch)

@inline write_utf8(io, ch)  = ch <= 0xffff ? _write_ucs2(io, ch) : _write_utf8_4(io, ch)
@inline write_utf16(io, ch) = ch <= 0xffff ? write(io, ch%UInt16) : write(io, get_utf16(ch)...)

@inline print(io::IO, ch::UCS2Chr)  = _write_ucs2(io, codepoint(ch))
@inline print(io::IO, ch::UTF32Chr) = write_utf8(io, codepoint(ch))

## outputting Str strings and Chr characters ##

@inline _write(::Type{<:CSE}, io, ch::AbsChar)    = write(io, codepoint(ch))
@inline _write(::Type{UTF8CSE}, io, ch::AbsChar)  = write_utf8(io, codepoint(ch))
@inline _write(::Type{UTF16CSE}, io, ch::AbsChar) = write_utf16(io, codepoint(ch))

@inline _write(::Type{RawUTF8CSE}, io, ch::AbsChar) = print(io, codepoint(ch))

@inline write(io::IO, ch::Chr) = write(io, codepoint(ch))

# Printing bytes
_print(io, ch::UInt8) = ch <= 0x7f ? write(io, ch) : _write_utf8_2(io, ch)
print(io::IO, ch::LatinChars) = (_print(io, ch%UInt8) ; nothing)

read(io::IO, ::Type{C}) where {CS,T,C<:Chr{CS,T}} = C(read(io, T))
