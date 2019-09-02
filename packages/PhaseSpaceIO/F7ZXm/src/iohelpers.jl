struct FastReadIO{I <: IO,T} <: IO
    io::I
    ref::Base.RefValue{T}
end

FastReadIO(io::IO) = FastReadIO(io, Ref(0x00))
FastReadIO(o::FastReadIO) = o

for f in [:seekstart, :seekend, :position, :eof, :close]
    @eval Base.$f(o::FastReadIO) = $f(o.io)
end
Base.seek(o::FastReadIO, pos) = seek(o.io, pos)

function read_(o::FastReadIO, ::Type{UInt8})
    read!(o.io, o.ref)
    o.ref[]
end

function read_(o::FastReadIO, ::Type{UInt32})
    b4 = UInt32(read_(o, UInt8)) << 0
    b3 = UInt32(read_(o, UInt8)) << 8
    b2 = UInt32(read_(o, UInt8)) << 16
    b1 = UInt32(read_(o, UInt8)) << 24
    b1 + b2 + b3 + b4
end

read_(o::FastReadIO, ::Type{Nothing}) = nothing
read_(o::FastReadIO, ::Type{Float32}) = reinterpret(Float32, read_(o, UInt32))
read_(o::FastReadIO, ::Type{Int32}) = reinterpret(Int32, read_(o, UInt32))
read_(o::FastReadIO, ::Type{Int8}) = reinterpret(Int8, read_(o, UInt8))
read_(o::FastReadIO, ::Type{Char}) = Char(read_(o, UInt8))

read_(io::IO, ::Type{T}) where {T} = read(io, T)
read_(io::IO, ::Type{Nothing}) = nothing

@generated function read_(io::IO, ::Type{T}) where {T <: Tuple}
    args = [:(read_(io, $Ti)) for Ti ∈ T.parameters]
    Expr(:call, :tuple, args...)
end

function bytelength(io::IO)
    # this dose the same as filesize
    # except that filesize does not work
    # on IOBuffer
    init_pos = position(io)
    seekstart(io)
    start_pos = position(io)
    seekend(io)
    end_pos = position(io)
    seek(io, init_pos)
    end_pos - start_pos
end

function getbit(x::Integer, i)
    (x & (1 << i)) == (1 << i)
end

function setbit(x::Integer, val::Bool, i)
    T = typeof(x)
    newbit = T(val)
    mask = (T(-newbit) ⊻ x) & (T(1) << i)
    x ⊻ mask
end
