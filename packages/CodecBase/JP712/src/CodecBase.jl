module CodecBase

export
    # base 16
    Base16Encoder,
    Base16EncoderStream,
    Base16Decoder,
    Base16DecoderStream,

    # base 32
    Base32Encoder,
    Base32EncoderStream,
    Base32Decoder,
    Base32DecoderStream,

    # base 64
    Base64Encoder,
    Base64EncoderStream,
    Base64Decoder,
    Base64DecoderStream

import TranscodingStreams:
    TranscodingStreams,
    TranscodingStream,
    Codec,
    Memory,
    Error

macro unreachable()
    :(@assert false "unreachable")
end

include("error.jl")
include("state.jl")
include("buffer.jl")
include("codetable.jl")
include("base16/codetable.jl")
include("base16/encoder.jl")
include("base16/decoder.jl")
include("base32/codetable.jl")
include("base32/encoder.jl")
include("base32/decoder.jl")
include("base64/codetable.jl")
include("base64/encoder.jl")
include("base64/decoder.jl")

end # module
