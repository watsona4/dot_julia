# Base64 Encoder
# ==============

struct Base64Encoder <: Codec
    table::CodeTable64
    state::State
    buffer::Buffer
end

Base64Encoder(table::CodeTable64) = Base64Encoder(table, State(), Buffer(2))

"""
    Base64Encoder(;urlsafe::Bool=false)

Create a base64 encoding codec.

Arguments
---------
- `urlsafe`: use `-` and `_` as the last two values
"""
function Base64Encoder(;urlsafe::Bool=false)
    if urlsafe
        table = BASE64_URLSAFE
    else
        table = BASE64_STD
    end
    return Base64Encoder(table)
end

const Base64EncoderStream{S} = TranscodingStream{Base64Encoder,S} where S<:IO

"""
    Base64EncoderStream(stream::IO; kwargs...)

Create a base64 encoding stream (see `Base64Encoder` for `kwargs`).
"""
function Base64EncoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base64Encoder(;kwargs...), stream)
end

function TranscodingStreams.startproc(
        codec :: Base64Encoder,
        state :: Symbol,
        error :: Error)
    start!(codec.state)
    empty!(codec.buffer)
    return :ok
end

function TranscodingStreams.process(
        codec  :: Base64Encoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    table = codec.table
    state = codec.state
    buffer = codec.buffer

    # Check if we can encode data.
    if !is_running(state)
        error[] = ArgumentError("encoding is already finished")
        return 0, 0, :error
    elseif output.size < 4
        # Need more output space.
        return 0, 0, :ok
    end

    # Load the first three bytes.
    i = j = 0
    while buffer.size < 2 && i < input.size
        buffer[buffer.size+=1] = input[i+=1]
    end
    b1 = b2 = b3 = 0x00
    npad = 0
    status = :ok
    if i < input.size
        b1 = buffer[1]
        b2 = buffer[2]
        b3 = input[i+=1]
    elseif input.size == 0
        # Found the end of the input.
        if buffer.size == 0
            finish!(state)
            return i, j, :end
        elseif buffer.size == 1
            b1 = buffer[1]
            npad = 2
        elseif buffer.size == 2
            b1 = buffer[1]
            b2 = buffer[2]
            npad = 1
        else
            @unreachable
        end
        status = :end
    else
        # Need more data to encode.
        return i, j, :ok
    end
    empty!(buffer)

    # Encode the body.
    @inbounds while true
        output[j+1] = encode(table, b1 >> 2          )
        output[j+2] = encode(table, b1 << 4 | b2 >> 4)
        output[j+3] = encode(table, b2 << 2 | b3 >> 6)
        output[j+4] = encode(table,           b3     )
        j += 4
        if i + 3 ≤ input.size && j + 4 ≤ output.size
            b1 = input[i+1]
            b2 = input[i+2]
            b3 = input[i+3]
            i += 3
        else
            break
        end
    end

    # Epilogue.
    while npad > 0
        output[j-npad+1] = table.padcode
        npad -= 1
    end
    if status == :end || status == :error
        finish!(state)
    end
    return i, j, status
end
