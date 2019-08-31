# CodeTable
# =========

struct CodeTable{base}
    # n-bit code => ascii code
    encodeword::Vector{UInt8}

    # ascii code => n-bit code
    decodeword::Vector{UInt8}

    # ascii code for padding
    padcode::UInt8
end

function Base.copy(table::CodeTable{base}) where base
    return CodeTable{base}(
        copy(table.encodeword),
        copy(table.decodeword),
        table.padcode)
end

const whitespace = "\t\n\v\f\r "

function ignorecode end

"""
    ignorechars!(table::CodeTable, asciichars::String)

Add characters that will be ignored while decoding.
"""
function ignorechars!(table::CodeTable, asciichars::String)
    if !isascii(asciichars)
        throw(ArgumentError("ignored characters must be ASCII"))
    end
    for char in asciichars
        code = UInt8(char)
        table.decodeword[code+1] = ignorecode(typeof(table))
    end
    return table
end
