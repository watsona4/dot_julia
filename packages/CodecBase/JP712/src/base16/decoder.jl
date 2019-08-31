# Base16 Decoder
# ==============

struct Base16Decoder <: Codec
    table::CodeTable16
    state::State
    buffer::Buffer
end

Base16Decoder(table::CodeTable16) = Base16Decoder(table, State(), Buffer(1))

"""
    Base16Decoder(;ignore::String=$(escape_string(whitespace)))

Create a base16 decoding codec.

Arguments
---------
- `ignore`: ASCII characters that will be ignored while decoding
"""
function Base16Decoder(;ignore::String=whitespace)
    table = copy(BASE16_UPPER)
    ignorechars!(table, ignore)
    return Base16Decoder(table)
end

const Base16DecoderStream{S} = TranscodingStream{Base16Decoder,S} where S<:IO

"""
    Base16DecoderStream(stream::IO; kwargs...)

Create a base16 decoding stream (see `Base16Decoder` for `kwargs`).
"""
function Base16DecoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base16Decoder(;kwargs...), stream)
end

function TranscodingStreams.startproc(
        codec :: Base16Decoder,
        state :: Symbol,
        error :: Error)
    start!(codec.state)
    empty!(codec.buffer)
    return :ok
end

function TranscodingStreams.process(
        codec  :: Base16Decoder,
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
    elseif output.size < 1
        # Need more output space.
        return 0, 0, :ok
    end

    # Load the first bytes.
    i = j = 0
    if buffer.size < 1 && i < input.size
        buffer[buffer.size+=1] = input[i+=1]
    end
    c1 = c2 = BASE16_CODEIGN
    if buffer.size ≥ 1
        c1 = decode(table, buffer[1])
    end
    empty!(buffer)

    # Start decoding loop.
    status = :ok
    @inbounds while true
        if c1 > 0x0f || c2 > 0x0f
            i, j, status = decode16_irregular(table, c1, c2, input, i, output, j, error)
        else
            output[j+1] = c1 << 4 | c2
            j += 1
        end
        if i + 2 ≤ input.size && j + 1 ≤ output.size
            c1 = decode(table, input[i+1])
            c2 = decode(table, input[i+2])
            i += 2
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

# Decode irregular code (e.g. non-alphabet, etc.).
function decode16_irregular(table, c1, c2, input, i, output, j, error)
    # Skip ignored chars.
    while true
        if c1 == BASE16_CODEIGN
            c1 = c2
        elseif c2 == BASE16_CODEIGN
            # pass
        else
            break
        end
        if i + 1 ≤ input.size
            c2 = decode(table, input[i+=1])
        else
            c2 = BASE16_CODEEND
            break
        end
    end

    # Write output.
    if c1 ≤ 0x0f && c2 ≤ 0x0f
        output[j+=1] = c1 << 4 | c2
        status = :ok
    elseif c1 == BASE16_CODEIGN && c2 == BASE16_CODEEND
        status = :end
    else
        error[] = DecodeError("invalid base16 data")
        status = :error
    end
    return i, j, status
end
