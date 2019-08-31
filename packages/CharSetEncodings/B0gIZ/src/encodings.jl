# Encoding support
#
# Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
# Licensed under MIT License, see LICENSE.md
# 
# Encodings inspired from collaboration with @nalimilan (Milan Bouchet-Valat) on
# [StringEncodings](https://github.com/nalimilan/StringEncodings.jl)

@api public  Encoding, Native1Byte, UTF8Encoding
@api develop encoding_types

struct Encoding{Enc} end

"""List of installed encodings"""
const encoding_types = []

Encoding(s) = Encoding{Symbol(s)}()

const Native1Byte  = Encoding{:Byte}
const UTF8Encoding = Encoding{:UTF8}

push!(encoding_types, Native1Byte, UTF8Encoding)

# Allow handling different endian encodings

for (n, l, b, s) in (("2Byte", :LE2,     :BE2,     "16-bit"),
                     ("4Byte", :LE4,     :BE4,     "32-bit"),
                     ("UTF16", :UTF16LE, :UTF16BE, "UTF-16"))
    nat, swp = BIG_ENDIAN ? (b, l) : (l, b)
    natnam = symstr("Native",  n)
    swpnam = symstr("Swapped", n)
    @eval const $natnam = Encoding{$(quotesym("N", n))}
    @eval const $swpnam = Encoding{$(quotesym("S", n))}
    @eval const $nat = $natnam
    @eval const $swp = $swpnam
    @eval push!(encoding_types, $natnam, $swpnam)
    @eval @api public $natnam, $swpnam
end

show(io::IO, ::Type{Encoding{S}}) where {S}  = print(io, "Encoding{:", string(S), "}")

encoding(::Type{T}) where {T<:AbstractString} = encoding(cse(T)) # Default unless overridden
encoding(str::AbstractString) = encoding(cse(str))
