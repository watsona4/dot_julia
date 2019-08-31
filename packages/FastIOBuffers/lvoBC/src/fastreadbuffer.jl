struct FastReadBuffer{V<:AbstractVector{UInt8}} <: IO
    data::V
    position::Base.RefValue{Int} # last read position
end

FastReadBuffer(data::AbstractVector{UInt8}) = FastReadBuffer(data, Ref(0))
FastReadBuffer() = FastReadBuffer(Vector{UInt8}())

"""
    setdata!(buf::FastReadBuffer, data::AbstractVector{UInt8))

Copy the data in `data` to the internal data buffer in `buf`
and reset the position to the beginning.
"""
function setdata!(buf::FastReadBuffer, data::AbstractVector{UInt8})
    n = length(data)
    resize!(buf.data, n)
    unsafe_copyto!(buf.data, 1, data, 1, n)
    buf.position[] = 0
    buf
end

@inline function Base.read(buf::FastReadBuffer, ::Type{UInt8})
    nextpos = buf.position[] + 1
    nextpos > length(buf.data) && throw(EOFError())
    buf.position[] = nextpos
    @inbounds return buf.data[nextpos]
end

@inline Base.read(buf::FastReadBuffer, ::Type{Int8}) = reinterpret(Int8, read(buf, UInt8))

@inline function Base.read(
            buf::FastReadBuffer,
            T::Union{map(t->Type{t}, Any[Int16,UInt16,Int32,UInt32,Int64,UInt64,Int128,UInt128,Float16,Float32,Float64])...})
    n = Core.sizeof(T)
    pos = buf.position[]
    nextpos = pos + n
    nextpos > length(buf.data) && throw(EOFError())
    data = buf.data
    ret = @static if isdefined(Base, :GC)
        GC.@preserve data begin
            ptr::Ptr{T} = pointer(data, pos + 1)
            unsafe_load(ptr)
        end
    else
        ptr::Ptr{T} = pointer(data, pos + 1)
        unsafe_load(ptr)
    end
    buf.position[] = nextpos
    ret
end

function Base.unsafe_read(buf::FastReadBuffer, ptr::Ptr{UInt8}, nb::UInt)
    # from https://github.com/JuliaLang/julia/blob/5a456f398408718cf9dff123e0355fb68319064f/base/iobuffer.jl#L158
    avail = bytesavailable(buf)
    adv = min(avail, nb)
    @static if isdefined(Base, :GC)
        GC.@preserve buf unsafe_copyto!(ptr, pointer(buf.data, buf.position[] + 1), adv)
    else
        unsafe_copyto!(ptr, pointer(buf.data, buf.position[] + 1), adv)
    end
    buf.position[] += adv
    if nb > avail
        throw(EOFError())
    end
    nothing
end

function Base.readbytes!(buf::FastReadBuffer, b::Array{UInt8}, nb=length(b))
    # from https://github.com/JuliaLang/julia/blob/9d85f7fd738febabab46275678e3987ac477dbfc/base/iobuffer.jl#L429
    nr = min(nb, bytesavailable(buf))
    if length(b) < nr
        resize!(b, nr)
    end
    if nr > length(b) || nr < 0
        throw(BoundsError())
    end
    @static if isdefined(Base, :GC)
        GC.@preserve b begin
            unsafe_read(buf, pointer(b), UInt(nr))
        end
    else
        unsafe_read(buf, pointer(b), UInt(nr))
    end
    nr
end

function Base.seek(buf::FastReadBuffer, n::Integer)
    buf.position[] = max(min(n, length(buf.data)), 0)
    buf
end

Base.seekend(buf::FastReadBuffer) = buf.position[] = length(buf.data)
Base.position(buf::FastReadBuffer) = buf.position[]
Base.readavailable(buf::FastReadBuffer) = read(buf, bytesavailable(buf))
Base.isopen(buf::FastReadBuffer) = true
Base.close(buf::FastReadBuffer) = throw(MethodError("Unsupported operation"))
Base.skip(buf::FastReadBuffer, n::Integer) = seek(buf, buf.position[] + n)
Base.bytesavailable(buf::FastReadBuffer) = length(buf.data) - buf.position[]
Base.eof(buf::FastReadBuffer) = buf.position[] >= length(buf.data)
Base.iswritable(buf::FastReadBuffer) = false
Base.isreadable(buf::FastReadBuffer) = true
