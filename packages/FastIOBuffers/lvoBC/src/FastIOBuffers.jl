module FastIOBuffers

export
    FastWriteBuffer,
    FastReadBuffer

export
    setdata!

include("fastwritebuffer.jl")
include("fastreadbuffer.jl")

end # module
