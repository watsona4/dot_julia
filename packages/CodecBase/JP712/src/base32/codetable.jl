# CodeTable32
# ===========

const CodeTable32 = CodeTable{32}

const BASE32_CODEPAD = 0x20  # PADding
const BASE32_CODEIGN = 0x21  # IGNore
const BASE32_CODEEND = 0x22  # END
const BASE32_CODEERR = 0xff  # ERRor

ignorecode(::Type{CodeTable32}) = BASE32_CODEIGN

"""
    CodeTable32(asciicode::String, pad::Char; casesensitive::Bool=false)

Create a code table for base32.
"""
function CodeTable32(asciicode::String, pad::Char; casesensitive::Bool=false)
    if !isascii(asciicode) || !isascii(pad)
        throw(ArgumentError("the code table must be ASCII"))
    elseif length(asciicode) != 32
        throw(ArgumentError("the code size must be 32"))
    end
    encodeword = Vector{UInt8}(undef, 32)
    decodeword = Vector{UInt8}(undef, 128)
    fill!(decodeword, BASE32_CODEERR)
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
    padcode = UInt8(pad)
    decodeword[padcode+1] = BASE32_CODEPAD
    return CodeTable32(encodeword, decodeword, padcode)
end

@inline function encode(table::CodeTable32, byte::UInt8)
    return table.encodeword[Int(byte & 0x1f) + 1]
end

@inline function decode(table::CodeTable32, byte::UInt8)
    return table.decodeword[Int(byte)+1]
end

"""
The standard base32 code table (cf. Table 3 of RFC4648).
"""
const BASE32_STD = CodeTable32("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", '=')

"""
The extended hex code table (cf. Table 4 of RFC4648).
"""
const BASE32_HEX = CodeTable32("0123456789ABCDEFGHIJKLMNOPQRSTUV", '=')
