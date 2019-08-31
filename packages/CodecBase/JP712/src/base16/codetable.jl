# CodeTable16
# ===========

const CodeTable16 = CodeTable{16}

const BASE16_CODEIGN = 0x10  # IGNore
const BASE16_CODEEND = 0x11  # END
const BASE16_CODEERR = 0xff  # ERRor

ignorecode(::Type{CodeTable16}) = BASE16_CODEIGN

"""
    CodeTable16(asciicode:::String; casesensitive::Bool=false)

Create a code table for base16.
"""
function CodeTable16(asciicode::String; casesensitive::Bool=false)
    if !isascii(asciicode)
        throw(ArgumentError("the code table must be ASCII"))
    elseif length(asciicode) != 16
        throw(ArgumentError("the code size must be 16"))
    end
    encodeword = Vector{UInt8}(undef, 16)
    decodeword = Vector{UInt8}(undef, 256)
    fill!(decodeword, BASE16_CODEERR)
    for (i, char) in enumerate(asciicode)
        bits = UInt8(i-1)
        code = UInt8(char)
        encodeword[bits+1] = code
        decodeword[code+1] = bits
        if !casesensitive
            if isuppercase(char)
                code = UInt8(lowercase(char))
                decodeword[code+1] = bits
            end
            if islowercase(char)
                code = UInt8(uppercase(char))
                decodeword[code+1] = bits
            end
        end
    end
    # NOTE: The padcode is not used.
    return CodeTable16(encodeword, decodeword, 0x00)
end

@inline function encode(table::CodeTable16, x::UInt8)
    return table.encodeword[Int(x)+1]
end

@inline function decode(table::CodeTable16, x::UInt8)
    return table.decodeword[Int(x)+1]
end

"""
The hexadecimal base16 code table (encoding: uppercase; decoding: case-insensitive).
"""
const BASE16_UPPER = CodeTable16("0123456789ABCDEF")

"""
The hexadecimal base16 code table (encoding: lowercase; decoding: case-insensitive).
"""
const BASE16_LOWER = CodeTable16("0123456789abcdef")
