__precompile__(true)

module RingBuffers

export RingBuffer, notifyhandle, framesreadable, frameswritable
export writeavailable, writeavailable!, readavailable! # these don't exist in Base
export PaUtilRingBuffer

import Base: read, read!, readavailable, write, flush
import Base: wait, notify
import Base: unsafe_convert, pointer
import Base: isopen, close

using Base: AsyncCondition
import Compat
import Compat: Libdl, Cvoid, undef, popfirst!, @compat

depsjl = joinpath(@__DIR__, "..", "deps", "deps.jl")
isfile(depsjl) ? include(depsjl) : error("RingBuffers not properly installed. Please run Pkg.build(\"RingBuffers\")")
__init__() = check_deps()

include("pa_ringbuffer.jl")

"""
    RingBuffer{T}(nchannels, nframes)

A lock-free ringbuffer wrapping PortAudio's implementation. The underlying
representation stores multi-channel data as interleaved. The buffer will hold
`nframes` frames.

This ring buffer can be used to pass data between tasks similar to the built-in
`Channel` type, but it has the additional ability to pass data to and from C
code running on a different thread. The C code can use the API defined in
`pa_ringbuffer.h`. Note that this is only safe with a single-threaded reader and
single-threaded writer.
"""
struct RingBuffer{T}
    pabuf::PaUtilRingBuffer
    nchannels::Int
    readers::Vector{Condition}
    writers::Vector{Condition}
    datanotify::AsyncCondition

    function RingBuffer{T}(nchannels, frames) where {T}
        frames = nextpow(2, frames)
        buf = PaUtilRingBuffer(sizeof(T) * nchannels, frames)
        new(buf, nchannels, Condition[], Condition[], AsyncCondition())
    end
end

###############
# Writing
###############

"""
    write(rbuf::RingBuffer{T}, data::AbstractArray{T}[, nframes])

Write `nframes` frames to `rbuf` from `data`. Assumes the data is interleaved.
If the buffer is full the call will block until space is available or the ring
buffer is closed. If `data` is a `Vector`, it's treated as a block of memory
from which to read the interleaved data. If it's a `Matrix`, it is treated as
nchannels × nframes.

Returns the number of frames written, which should be equal to the requested
number unless the buffer was closed prematurely.
"""
function write(rbuf::RingBuffer{T}, data::AbstractArray{T}, nframes) where {T}
    if length(data) < nframes * rbuf.nchannels
        dframes = (div(length(data), rbuf.nchannels))
        throw(ErrorException("data array is too short ($dframes frames) for requested write ($nframes frames)"))
    end

    isopen(rbuf) || return 0

    cond = Condition()
    nwritten = 0
    try
        push!(rbuf.writers, cond)
        if length(rbuf.writers) > 1
            # we're behind someone in the queue
            wait(cond)
            isopen(rbuf) || return 0
        end
        # now we're in the front of the queue
        n = PaUtil_WriteRingBuffer(rbuf.pabuf,
                                   pointer(data),
                                   nframes)
        nwritten += n
        # notify any waiting readers that there's data available
        notify(rbuf.datanotify.cond)
        while nwritten < nframes
            wait(rbuf.datanotify)
            isopen(rbuf) || return nwritten
            n = PaUtil_WriteRingBuffer(rbuf.pabuf,
                                       pointer(data)+(nwritten*rbuf.nchannels*sizeof(T)),
                                       nframes-nwritten)
            nwritten += n
            # notify any waiting readers that there's data available
            notify(rbuf.datanotify.cond)
        end
    finally
        # we're done, remove our condition and notify the next writer if necessary
        popfirst!(rbuf.writers)
        if length(rbuf.writers) > 0
           notify(rbuf.writers[1])
        end
    end

    nwritten
end

function write(rbuf::RingBuffer{T}, data::AbstractMatrix{T}) where {T}
    if size(data, 1) != rbuf.nchannels
        throw(ErrorException(
            "Tried to write a $(size(data, 1))-channel array to a $(rbuf.nchannels)-channel ring buffer"))
    end
    write(rbuf, data, size(data, 2))
end

function write(rbuf::RingBuffer{T}, data::AbstractVector{T}) where {T}
    write(rbuf, data, div(length(data), rbuf.nchannels))
end

"""
    frameswritable(rbuf::RingBuffer)

Returns the number of frames that can be written to the ring buffer without
blocking.
"""
function frameswritable(rbuf::RingBuffer)
    PaUtil_GetRingBufferWriteAvailable(rbuf.pabuf)
end

"""
    writeavailable(rbuf::RingBuffer{T}, data::AbstractArray{T}[, nframes])

Write up to `nframes` frames to `rbuf` from `data` without blocking. If `data`
is a `Vector`, it's treated as a block of memory from which to read the
interleaved data. If it's a `Matrix`, it is treated as nchannels × nframes.

Returns the number of frames written.
"""
function writeavailable(rbuf::RingBuffer{T}, data::AbstractVector{T},
                        nframes=div(length(data), rbuf.nchannels)) where {T}
    write(rbuf, data, min(nframes, frameswritable(rbuf)))
end

function writeavailable(rbuf::RingBuffer{T}, data::AbstractMatrix{T},
                        nframes=size(data, 2)) where {T}
    write(rbuf, data, min(nframes, frameswritable(rbuf)))
end

# basically add ourselves to the queue as if we're a writer, but wait until the
# ringbuf is emptied
function flush(rbuf::RingBuffer)
    isopen(rbuf) || return

    cond = Condition()
    try
        push!(rbuf.writers, cond)
        if length(rbuf.writers) > 1
            # we're behind someone in the queue
            wait(cond)
            isopen(rbuf) || return
        end
        # now we're in the front of the queue
        while frameswritable(rbuf) < rbuf.pabuf.bufferSize
            wait(rbuf.datanotify)
            isopen(rbuf) || return
        end

    finally
        # we're done, remove our condition and notify the next writer if necessary
        popfirst!(rbuf.writers)
        if length(rbuf.writers) > 0
           notify(rbuf.writers[1])
        end
    end
end

###############
# Reading
###############

"""
    read!(rbuf::RingBuffer, data::AbstractArray[, nframes])

Read `nframes` frames from `rbuf` into `data`. Data will be interleaved.
If the buffer is empty the call will block until data is available or the ring
buffer is closed. If `data` is a `Vector`, it's treated as a block of memory
in which to write the interleaved data. If it's a `Matrix`, it is treated as
nchannels × nframes.

Returns the number of frames read, which should be equal to the requested
number unless the buffer was closed prematurely.
"""
function read!(rbuf::RingBuffer{T}, data::AbstractArray{T}, nframes) where {T}
    if length(data) < nframes * rbuf.nchannels
        dframes = (div(length(data), rbuf.nchannels))
        throw(ErrorException("data array is too short ($dframes frames) for requested read ($nframes frames)"))
    end

    cond = Condition()
    nread = 0
    try
        push!(rbuf.readers, cond)
        if length(rbuf.readers) > 1
            # we're behind someone in the queue
            wait(cond)
            isopen(rbuf) || return 0
        end
        # now we're in the front of the queue
        n = PaUtil_ReadRingBuffer(rbuf.pabuf,
                                  pointer(data),
                                  nframes)
        nread += n
        # notify any waiting writers that there's space available
        notify(rbuf.datanotify.cond)
        while nread < nframes
            wait(rbuf.datanotify)
            isopen(rbuf) || return nread
            n = PaUtil_ReadRingBuffer(rbuf.pabuf,
                                      pointer(data)+(nread*rbuf.nchannels*sizeof(T)),
                                      nframes-nread)
            nread += n
            # notify any waiting writers that there's space available
            notify(rbuf.datanotify.cond)
        end
    finally
        # we're done, remove our condition and notify the next reader if necessary
        popfirst!(rbuf.readers)
        if length(rbuf.readers) > 0
           notify(rbuf.readers[1])
        end
    end

    nread
end

function read!(rbuf::RingBuffer{T}, data::AbstractMatrix{T}) where {T}
    if size(data, 1) != rbuf.nchannels
        throw(ErrorException(
            "Tried to write a $(size(data, 1))-channel array to a $(rbuf.nchannels)-channel ring buffer"))
    end
    read!(rbuf, data, size(data, 2))
end

function read!(rbuf::RingBuffer{T}, data::AbstractVector{T}) where {T}
    read!(rbuf, data, div(length(data), rbuf.nchannels))
end


"""
    read(rbuf::RingBuffer, nframes)

Read `nframes` frames from `rbuf` and return an (nchannels × nframes) `Array`
holding the interleaved data. If the buffer is empty the call will block until
data is available or the ring buffer is closed.
"""
function read(rbuf::RingBuffer{T}, nframes) where {T}
    data = Array{T}(undef, rbuf.nchannels, nframes)
    nread = read!(rbuf, data, nframes)

    if nread < nframes
        data[:, 1:nread]
    else
        data
    end
end

"""
    read(rbuf::RingBuffer; blocksize=4096)

Read `blocksize` frames at a time from `rbuf` until the ringbuffer is closed,
and return an (nchannels × nframes) `Array` holding the data. When no data is
available  the call will block until it can read more or the ring buffer is
closed.
"""
function read(rbuf::RingBuffer{T}; blocksize=4096) where {T}
    readbuf = Array{T}(undef, rbuf.nchannels, blocksize)
    # during accumulation we keep the channels separate so we can grow the
    # arrays without needing to copy data around as much
    cumbufs = [Vector{T}() for _ in 1:rbuf.nchannels]
    while true
        n = read!(rbuf, readbuf)
        for ch in 1:length(cumbufs)
            append!(cumbufs[ch], @view readbuf[ch, 1:n])
        end
        n == blocksize || break
    end
    vcat((x' for x in cumbufs)...)
end

"""
    frameswritable(rbuf::RingBuffer)

Returns the number of frames that can be written to the ring buffer without
blocking.
"""
function framesreadable(rbuf::RingBuffer)
    PaUtil_GetRingBufferReadAvailable(rbuf.pabuf)
end

"""
    readavailable!(rbuf::RingBuffer{T}, data::AbstractArray{T}[, nframes])

Read up to `nframes` frames from `rbuf` into `data` without blocking. If `data`
is a `Vector`, it's treated as a block of memory to write the interleaved data
to. If it's a `Matrix`, it is treated as nchannels × nframes.

Returns the number of frames read.
"""
function readavailable!(rbuf::RingBuffer{T}, data::AbstractVector{T},
                        nframes=div(length(data), rbuf.nchannels)) where {T}
    read!(rbuf, data, min(nframes, framesreadable(rbuf)))
end

function readavailable!(rbuf::RingBuffer{T}, data::AbstractMatrix{T},
                        nframes=size(data, 2)) where {T}
    read!(rbuf, data, min(nframes, framesreadable(rbuf)))
end

"""
    readavailable(rbuf::RingBuffer[, nframes])

Read up to `nframes` frames from `rbuf` into `data` without blocking. If `data`
is a `Vector`, it's treated as a block of memory to write the interleaved data
to. If it's a `Matrix`, it is treated as nchannels × nframes.

Returns an (nchannels × nframes) `Array`.
"""
function readavailable(rbuf::RingBuffer, nframes)
    read(rbuf, min(nframes, framesreadable(rbuf)))
end

function readavailable(rbuf::RingBuffer)
    read(rbuf, framesreadable(rbuf))
end

######################
# Resource Management
######################

function close(rbuf::RingBuffer)
    close(rbuf.pabuf)
    # wake up any waiting readers or writers
    notify(rbuf.datanotify.cond)
end

isopen(rbuf::RingBuffer) = isopen(rbuf.pabuf)

# """
#     notify(rbuf::RingBuffer)
#
# Notify the ringbuffer that new data might be available, which will wake up
# any waiting readers or writers. This is safe to call from a separate thread
# context.
# """
# notify(rbuf::RingBuffer) = ccall(:uv_async_send, rbuf.datacond.handle)

"""
    notifyhandle(rbuf::RingBuffer)

Return the AsyncCondition handle that can be used to wake up the buffer from
another thread.
"""
notifyhandle(rbuf::RingBuffer) = rbuf.datanotify.handle

"""
    pointer(rbuf::RingBuffer)

Return the pointer to the underlying PaUtilRingBuffer that can be passed to C
code and manipulated with the pa_ringbuffer.h API.
"""
pointer(rbuf::RingBuffer) = Ptr{PaUtilRingBuffer}(pointer_from_objref(rbuf.pabuf))

# set it up so we can pass this directly to `ccall` expecting a PA ringbuffer
unsafe_convert(::Type{Ptr{PaUtilRingBuffer}}, buf::RingBuffer) = unsafe_convert(Ptr{PaUtilRingBuffer}, buf.pabuf)

end # module
