# Base16 Encoder
# ==============

struct Base16Encoder <: Codec
    table::CodeTable16
    state::State
end

Base16Encoder(table::CodeTable16) = Base16Encoder(table, State())

"""
    Base16Encoder(;lowercase=false)

Create a base16 encoding codec.

Arguments
- `lowercase`: use [0-9a-f] instead of [0-9A-F].
"""
function Base16Encoder(;lowercase::Bool=false)
    if lowercase
        table = BASE16_LOWER
    else
        table = BASE16_UPPER
    end
    return Base16Encoder(table)
end

const Base16EncoderStream{S} = TranscodingStream{Base16Encoder,S} where S<:IO

"""
    Base16EncoderStream(stream::IO; kwargs...)

Create a base16 encoding stream (see `Base16Encoder` for `kwargs`).
"""
function Base16EncoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base16Encoder(;kwargs...), stream)
end

macro encode16(i, j1, j2)
    quote
        a = input[$(i)]
        output[$(j1)] = encode(table, a >> 4)
        output[$(j2)] = encode(table, a & 0x0f)
    end |> esc
end

function TranscodingStreams.startproc(
        codec :: Base16Encoder,
        state :: Symbol,
        error :: Error)
    start!(codec.state)
    return :ok
end

function TranscodingStreams.process(
        codec  :: Base16Encoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    table = codec.table
    state = codec.state

    # Check if we can encode data.
    if !is_running(state)
        error[] = ArgumentError("encoding is already finished")
        return 0, 0, :error
    elseif input.size == 0
        finish!(state)
        return 0, 0, :end
    elseif output.size < 2
        # Need more output space.
        return 0, 0, :ok
    end

    # Encode the data.
    i = j = 0
    k::Int = min(fld(input.size, 4), fld(output.size, 8))
    @inbounds while k > 0  # ≡ i + 4 ≤ input.size && j + 8 ≤ output.size
        # unrolled loop
        @encode16 i+1 j+1 j+2
        @encode16 i+2 j+3 j+4
        @encode16 i+3 j+5 j+6
        @encode16 i+4 j+7 j+8
        i += 4
        j += 8
        k -= 1
    end
    @inbounds while i + 1 ≤ input.size && j + 2 ≤ output.size
        @encode16 i+1 j+1 j+2
        i += 1
        j += 2
    end
    return i, j, :ok
end
