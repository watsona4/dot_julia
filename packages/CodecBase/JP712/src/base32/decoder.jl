# Base32 Decoder
# ==============

struct Base32Decoder <: Codec
    table::CodeTable32
    state::State
    buffer::Buffer
end

Base32Decoder(table::CodeTable32) = Base32Decoder(table, State(), Buffer(7))

"""
    Base32Decoder(;hex::Bool=false, ignore::String=$(escape_string(whitespace)))

Create a base32 decoding codec.

Arguments
---------
- `hex`: use extended hex alphabet (Table 4 of RFC4648)
- `ignore`: ASCII characters that will be ignored while decoding
"""
function Base32Decoder(;hex::Bool=false, ignore::String=whitespace)
    if hex
        table = BASE32_HEX
    else
        table = BASE32_STD
    end
    table = copy(table)
    ignorechars!(table, ignore)
    return Base32Decoder(table)
end

const Base32DecoderStream{S} = TranscodingStream{Base32Decoder,S} where S<:IO

"""
    Base32DecoderStream(stream::IO; kwargs...)

Create a base32 decoding stream (see `Base32Decoder` for `kwargs`).
"""
function Base32DecoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base32Decoder(;kwargs...), stream)
end

function TranscodingStreams.startproc(
        codec :: Base32Decoder,
        state :: Symbol,
        error :: Error)
    start!(codec.state)
    return :ok
end

function TranscodingStreams.process(
        codec  :: Base32Decoder,
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
    while buffer.size < 7 && i + 1 ≤ input.size
        buffer[buffer.size+=1] = input[i+=1]
    end
    c1 = c2 = c3 = c4 = c5 = c6 = c7 = c8 = BASE32_CODEIGN
    if buffer.size ≥ 1
        c1 = decode(table, buffer[1])
    end
    if buffer.size ≥ 2
        c2 = decode(table, buffer[2])
    end
    if buffer.size ≥ 3
        c3 = decode(table, buffer[3])
    end
    if buffer.size ≥ 4
        c4 = decode(table, buffer[4])
    end
    if buffer.size ≥ 5
        c5 = decode(table, buffer[5])
    end
    if buffer.size ≥ 6
        c6 = decode(table, buffer[6])
    end
    if buffer.size ≥ 7
        c7 = decode(table, buffer[7])
    end
    empty!(buffer)

    # Start decoding loop.
    #  01234567 89012345 67890123 45678901 23456789
    # +--------+--------+--------+--------+--------+
    # |< 1 >< 2| >< 3 ><| 4 >< 5 |>< 6 >< |7 >< 8 >|
    # +--------+--------+--------+--------+--------+
    status = :ok
    @inbounds while true
        if c1 > 0x1f || c2 > 0x1f || c3 > 0x1f || c4 > 0x1f ||
           c5 > 0x1f || c6 > 0x1f || c7 > 0x1f || c8 > 0x1f
           i, j, status = decode32_irregular(
               table,
               c1, c2, c3, c4, c5, c6, c7, c8,
               input,  i,
               output, j,
               error)
        else
            output[j+1] = c1 << 3 | c2 >> 2
            output[j+2] = c2 << 6 | c3 << 1 | c4 >> 4
            output[j+3] = c4 << 4 | c5 >> 1
            output[j+4] = c5 << 7 | c6 << 2 | c7 >> 3
            output[j+5] = c7 << 5 | c8
            j += 5
        end
        if i + 8 ≤ input.size && j + 5 ≤ output.size && status == :ok
            c1 = decode(table, input[i+1])
            c2 = decode(table, input[i+2])
            c3 = decode(table, input[i+3])
            c4 = decode(table, input[i+4])
            c5 = decode(table, input[i+5])
            c6 = decode(table, input[i+6])
            c7 = decode(table, input[i+7])
            c8 = decode(table, input[i+8])
            i += 8
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

function decode32_irregular(table, c1, c2, c3, c4, c5, c6, c7, c8, input, i, output, j, error)
    # Skip ignored chars.
    while true
        if c1 == BASE32_CODEIGN
            c1, c2, c3, c4, c5, c6, c7 = c2, c3, c4, c5, c6, c7, c8
        elseif c2 == BASE32_CODEIGN
            c2, c3, c4, c5, c6, c7 = c3, c4, c5, c6, c7, c8
        elseif c3 == BASE32_CODEIGN
            c3, c4, c5, c6, c7 = c4, c5, c6, c7, c8
        elseif c4 == BASE32_CODEIGN
            c4, c5, c6, c7 = c5, c6, c7, c8
        elseif c5 == BASE32_CODEIGN
            c5, c6, c7 = c6, c7, c8
        elseif c6 == BASE32_CODEIGN
            c6, c7 = c7, c8
        elseif c7 == BASE32_CODEIGN
            c7 = c8
        elseif c8 == BASE32_CODEIGN
            # pass
        else
            break
        end
        if i + 1 ≤ input.size
            c8 = decode(table, input[i+=1])
        else
            c8 = BASE32_CODEEND
            break
        end
    end

    # Write output.
    if max(c1, c2, c3, c4, c5, c6, c7, c8) ≤ 0x1f
        output[j+=1] = c1 << 3 | c2 >> 2
        output[j+=1] = c2 << 6 | c3 << 1 | c4 >> 4
        output[j+=1] = c4 << 4 | c5 >> 1
        output[j+=1] = c5 << 7 | c6 << 2 | c7 >> 3
        output[j+=1] = c7 << 5 | c8
        status = :ok
    elseif max(c1, c2, c3, c4, c5, c6, c7) ≤ 0x1f && c8 == BASE32_CODEPAD
        output[j+=1] = c1 << 3 | c2 >> 2
        output[j+=1] = c2 << 6 | c3 << 1 | c4 >> 4
        output[j+=1] = c4 << 4 | c5 >> 1
        output[j+=1] = c5 << 7 | c6 << 2 | c7 >> 3
        status = :end
    elseif max(c1, c2, c3, c4, c5) ≤ 0x1f && c6 == c7 == c8 == BASE32_CODEPAD
        output[j+=1] = c1 << 3 | c2 >> 2
        output[j+=1] = c2 << 6 | c3 << 1 | c4 >> 4
        output[j+=1] = c4 << 4 | c5 >> 1
        status = :end
    elseif max(c1, c2, c3, c4) ≤ 0x1f && c5 == c6 == c7 == c8 == BASE32_CODEPAD
        output[j+=1] = c1 << 3 | c2 >> 2
        output[j+=1] = c2 << 6 | c3 << 1 | c4 >> 4
        status = :end
    elseif max(c1, c2) ≤ 0x1f && c3 == c4 == c5 == c6 == c7 == c8 == BASE32_CODEPAD
        output[j+=1] = c1 << 3 | c2 >> 2
        status = :end
    elseif c1 == c2 == c3 == c4 == c5 == c6 == c7 == BASE32_CODEIGN && c8 == BASE32_CODEEND
        status = :end
    else
        error[] = DecodeError("invalid base32 data")
        status = :error
    end

    return i, j, status
end
