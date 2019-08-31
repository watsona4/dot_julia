# Compressor Codec
# ================

struct XzCompressor <: TranscodingStreams.Codec
    stream::LZMAStream
    preset::UInt32
    check::Cint
end

function Base.show(io::IO, codec::XzCompressor)
    print(io, summary(codec), "(level=$(codec.preset), check=$(codec.check))")
end

const DEFAULT_COMPRESSION_LEVEL = 6
const DEFAULT_CHECK = LZMA_CHECK_CRC64

"""
    XzCompressor(;level=$(DEFAULT_COMPRESSION_LEVEL), check=LZMA_CHECK_CRC64)

Create an xz compression codec.

Arguments
---------
- `level`: compression level (0..9)
- `check`: integrity check type (`LZMA_CHECK_{NONE,CRC32,CRC64,SHA256}`)
"""
function XzCompressor(;level::Integer=DEFAULT_COMPRESSION_LEVEL, check::Cint=DEFAULT_CHECK)
    if !(0 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within 0..9"))
    elseif check ∉ (LZMA_CHECK_NONE, LZMA_CHECK_CRC32, LZMA_CHECK_CRC64, LZMA_CHECK_SHA256)
        throw(ArgumentError("invalid integrity check"))
    end
    return XzCompressor(LZMAStream(), level, check)
end

const XzCompressorStream{S} = TranscodingStream{XzCompressor,S} where S<:IO

"""
    XzCompressorStream(stream::IO; kwargs...)

Create an xz compression stream (see `XzCompressor` for `kwargs`).
"""
function XzCompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:level, :check))
    return TranscodingStream(XzCompressor(;x...), stream; y...)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::XzCompressor)
    ret = easy_encoder(codec.stream, codec.preset, codec.check)
    if ret != LZMA_OK
        lzmaerror(codec.stream, ret)
    end
    return
end

function TranscodingStreams.finalize(codec::XzCompressor)
    free(codec.stream)
end

function TranscodingStreams.startproc(codec::XzCompressor, mode::Symbol, error::Error)
    ret = easy_encoder(codec.stream, codec.preset, codec.check)
    if ret != LZMA_OK
        error[] = ErrorException("xz error")
        return :error
    end
    return :ok
end

function TranscodingStreams.process(codec::XzCompressor, input::Memory, output::Memory, error::Error)
    stream = codec.stream
    stream.next_in = input.ptr
    stream.avail_in = input.size
    stream.next_out = output.ptr
    stream.avail_out = output.size
    ret = code(stream, input.size > 0 ? LZMA_RUN : LZMA_FINISH)
    Δin = Int(input.size - stream.avail_in)
    Δout = Int(output.size - stream.avail_out)
    if ret == LZMA_OK
        return Δin, Δout, :ok
    elseif ret == LZMA_STREAM_END
        return Δin, Δout, :end
    else
        error[] = ErrorException(lzma_error_string(ret))
        return Δin, Δout, :error
    end
end
