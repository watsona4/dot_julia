# Base64 Decoder
# ==============

struct Base64Decoder <: Codec
    table::CodeTable64
    state::State
    buffer::Buffer
end

Base64Decoder(table::CodeTable64) = Base64Decoder(table, State(), Buffer(3))

"""
    Base64Decoder(;urlsafe::Bool=false, ignore::String="$(escape_string(whitespace))")

Create a base64 decoding codec.

Arguments
---------
- `urlsafe`: use `-` and `_` as the last two values
- `ignore`: ASCII characters that will be ignored while decoding
"""
function Base64Decoder(;urlsafe::Bool=false, ignore::String=whitespace)
    if urlsafe
        table = BASE64_URLSAFE
    else
        table = BASE64_STD
    end
    table = copy(table)
    ignorechars!(table, ignore)
    return Base64Decoder(table)
end

const Base64DecoderStream{S} = TranscodingStream{Base64Decoder,S} where S<:IO

"""
    Base64DecoderStream(stream::IO; kwargs...)

Create a base64 decoding stream (see `Base64Decoder` for `kwargs`).
"""
function Base64DecoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base64Decoder(;kwargs...), stream)
end

function TranscodingStreams.startproc(
        codec :: Base64Decoder,
        state :: Symbol,
        error :: Error)
    start!(codec.state)
    return :ok
end

function TranscodingStreams.process(
        codec  :: Base64Decoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    table = codec.table
    state = codec.state
    buffer = codec.buffer

    # Check if we can encode data.
    if !is_running(state)
        error[] = ArgumentError("decoding is already finished")
        return 0, 0, :error
    elseif output.size < 3
        # Need more output space.
        return 0, 0, :ok
    end

    # Load the first bytes.
    i = j = 0
    while buffer.size < 3 && i < input.size
        buffer[buffer.size+=1] = input[i+=1]
    end
    c1 = c2 = c3 = c4 = BASE64_CODEIGN
    if buffer.size ≥ 1
        c1 = decode(table, buffer[1])
    end
    if buffer.size ≥ 2
        c2 = decode(table, buffer[2])
    end
    if buffer.size ≥ 3
        c3 = decode(table, buffer[3])
    end
    empty!(buffer)

    # Start decoding loop.
    status = :ok
    @inbounds while true
        if c1 > 0x3f || c2 > 0x3f || c3 > 0x3f || c4 > 0x3f
            i, j, status = decode64_irregular(table, c1, c2, c3, c4, input, i, output, j, error)
        else
            output[j+1] = c1 << 2 | c2 >> 4
            output[j+2] = c2 << 4 | c3 >> 2
            output[j+3] = c3 << 6 | c4
            j += 3
        end
        if i + 4 ≤ input.size && j + 3 ≤ output.size && status == :ok
            c1 = decode(table, input[i+1])
            c2 = decode(table, input[i+2])
            c3 = decode(table, input[i+3])
            c4 = decode(table, input[i+4])
            i += 4
        else
            break
        end
    end

    # Epilogue.
    if status == :end || status == :error
        finish!(state)
    end
    return i, j, status
end

# Decode irregular code (e.g. non-alphabet, padding, etc.).
function decode64_irregular(table, c1, c2, c3, c4, input, i, output, j, error)
    # Skip ignored chars.
    while true
        if c1 == BASE64_CODEIGN
            c1, c2, c3 = c2, c3, c4
        elseif c2 == BASE64_CODEIGN
            c2, c3 = c3, c4
        elseif c3 == BASE64_CODEIGN
            c3 = c4
        elseif c4 == BASE64_CODEIGN
            # pass
        else
            break
        end
        if i + 1 ≤ input.size
            c4 = decode(table, input[i+=1])
        else
            c4 = BASE64_CODEEND
            break
        end
    end

    # Write output.
    if c1 ≤ 0x3f && c2 ≤ 0x3f && c3 ≤ 0x3f && c4 ≤ 0x3f
        output[j+=1] = c1 << 2 | c2 >> 4
        output[j+=1] = c2 << 4 | c3 >> 2
        output[j+=1] = c3 << 6 | c4
        status = :ok
    elseif c1 ≤ 0x3f && c2 ≤ 0x3f && c3 ≤ 0x3f && c4 == BASE64_CODEPAD
        c4 = 0x00
        output[j+=1] = c1 << 2 | c2 >> 4
        output[j+=1] = c2 << 4 | c3 >> 2
        status = :end
    elseif c1 ≤ 0x3f && c2 ≤ 0x3f && c3 == c4 == BASE64_CODEPAD
        c3 = c4 = 0x00
        output[j+=1] = c1 << 2 | c2 >> 4
        status = :end
    elseif c1 == c2 == c3 == BASE64_CODEIGN && c4 == BASE64_CODEEND
        status = :end
    else
        error[] = DecodeError("invalid base64 data")
        status = :error
    end
    return i, j, status
end
