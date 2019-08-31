# CodeTable64
# ===========

const CodeTable64 = CodeTable{64}

const BASE64_CODEPAD = 0x40  # PADding
const BASE64_CODEIGN = 0x41  # IGNore
const BASE64_CODEEND = 0x42  # END
const BASE64_CODEERR = 0xff  # ERRor

ignorecode(::Type{CodeTable64}) = BASE64_CODEIGN

"""
    CodeTable64(asciicode::String, pad::Char)

Create a code table for base64.
"""
function CodeTable64(asciicode::String, pad::Char)
    if !isascii(asciicode) || !isascii(pad)
        throw(ArgumentError("the code table must be ASCII"))
    elseif length(asciicode) != 64
        throw(ArgumentError("the code size must be 64"))
    end
    encodeword = Vector{UInt8}(undef, 64)
    decodeword = Vector{UInt8}(undef, 256)
    fill!(decodeword, BASE64_CODEERR)
    for (i, char) in enumerate(asciicode)
        bits = UInt8(i-1)
        code = UInt8(char)
        encodeword[bits+1] = code
        decodeword[code+1] = bits
    end
    padcode = UInt8(pad)
    decodeword[padcode+1] = BASE64_CODEPAD
    return CodeTable64(encodeword, decodeword, padcode)
end

@inline function encode(table::CodeTable64, byte::UInt8)
    return table.encodeword[Int(byte & 0x3f) + 1]
end

@inline function decode(table::CodeTable64, byte::UInt8)
    return table.decodeword[Int(byte)+1]
end

"""
The standard base64 code table (cf. Table 1 of RFC4648).
"""
const BASE64_STD = CodeTable64(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", '=')

"""
The url-safe base64 code table (cf. Table 2 of RFC4648).
"""
const BASE64_URLSAFE = CodeTable64(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_", '=')
