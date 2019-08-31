# Base32 Encoder
# ==============

struct Base32Encoder <: Codec
    table::CodeTable32
    state::State
    buffer::Buffer
end

Base32Encoder(table::CodeTable32) = Base32Encoder(table, State(), Buffer(4))

"""
    Base32Encoder(;hex::Bool=false)

Create a base32 encoding codec.

Arguments
---------
- `hex`: use extended hex alphabet (Table 4 of RFC4648)
"""
function Base32Encoder(;hex::Bool=false)
    if hex
        table = BASE32_HEX
    else
        table = BASE32_STD
    end
    return Base32Encoder(table)
end

const Base32EncoderStream{S} = TranscodingStream{Base32Encoder,S} where S<:IO

"""
    Base32EncoderStream(stream::IO; kwargs...)

Create a base32 encoding stream (see `Base32Encoder` for `kwargs`).
"""
function Base32EncoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base32Encoder(;kwargs...), stream)
end

function TranscodingStreams.startproc(
        codec :: Base32Encoder,
        state :: Symbol,
        error :: Error)
    start!(codec.state)
    empty!(codec.buffer)
    return :ok
end

function TranscodingStreams.process(
        codec  :: Base32Encoder,
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
    elseif output.size < 8
        # Need more output space.
        return 0, 0, :ok
    end

    # Load the first five bytes.
    i = j = 0
    while buffer.size < 4 && i < input.size
        buffer[buffer.size+=1] = input[i+=1]
    end
    b1 = b2 = b3 = b4 = b5 = 0x00
    npad = 0
    status = :ok
    if i < input.size
        b1 = buffer[1]
        b2 = buffer[2]
        b3 = buffer[3]
        b4 = buffer[4]
        b5 = input[i+=1]
    elseif input.size == 0
        # Found the end of the input.
        if buffer.size == 0
            finish!(state)
            return i, j, :end
        elseif buffer.size == 1
            b1 = buffer[1]
            npad = 6
        elseif buffer.size == 2
            b1 = buffer[1]
            b2 = buffer[2]
            npad = 4
        elseif buffer.size == 3
            b1 = buffer[1]
            b2 = buffer[2]
            b3 = buffer[3]
            npad = 3
        elseif buffer.size == 4
            b1 = buffer[1]
            b2 = buffer[2]
            b3 = buffer[3]
            b4 = buffer[4]
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
    #  01234567 89012345 67890123 45678901 23456789
    # +--------+--------+--------+--------+--------+
    # |< 1 >< 2| >< 3 ><| 4 >< 5 |>< 6 >< |7 >< 8 >|
    # +--------+--------+--------+--------+--------+
    @inbounds while true
        output[j+1] = encode(table, b1 >> 3)
        output[j+2] = encode(table, b1 << 2 | b2 >> 6)
        output[j+3] = encode(table, b2 >> 1)
        output[j+4] = encode(table, b2 << 4 | b3 >> 4)
        output[j+5] = encode(table, b3 << 1 | b4 >> 7)
        output[j+6] = encode(table, b4 >> 2)
        output[j+7] = encode(table, b4 << 3 | b5 >> 5)
        output[j+8] = encode(table, b5)
        j += 8
        if i + 5 ≤ input.size && j + 8 ≤ output.size
            b1 = input[i+1]
            b2 = input[i+2]
            b3 = input[i+3]
            b4 = input[i+4]
            b5 = input[i+5]
            i += 5
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
