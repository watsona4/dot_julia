#### EGSHeader, EGSPhspIterator
struct EGSHeader{P<:EGSParticle}
    particlecount::Int32
    photoncount::Int32
    max_E_kin::Float32
    min_E_kin_electrons::Float32
    originalcount::Float32
end

function read_ZLAST(io::IO)
    mode = prod([read(io, Char) for _ in 1:5])
    if mode == "MODE0"
        Nothing
    elseif mode == "MODE2"
        Float32
    else
        error("Unknown mode $mode")
    end
end

function consume_egs_header(io::IO)
    ZLAST = read_ZLAST(io)
    P = EGSParticle{ZLAST}
    nphsp      = read(io, Int32)
    nphotphsp  = read(io, Int32)
    ekmaxphsp  = read(io, Float32)
    ekminphsp  = read(io, Float32)
    nincphsp   = read(io, Float32)
    EGSHeader{P}(nphsp, nphotphsp, ekmaxphsp, ekminphsp, nincphsp)
end

ptype(::Type{EGSHeader{P}}) where {P} = P

struct EGSPhspIterator{P <: EGSParticle, I <:IO} <: AbstractPhspIterator
    io::I
    header::EGSHeader{P}
    buffer::Base.RefValue{P}
    length::Int64
end

Base.eltype(::Type{<:EGSPhspIterator{P}}) where {P} = P

function egs_iterator(io::IO)
    h = consume_egs_header(io)
    total_size  = bytelength(io)
    P = ptype(h)
    len = Int64(total_size / sizeof(P)) - 1
    if len != h.particlecount
        @warn "Particle count according to the header is $(h.particlecount), while there are actually $(len) particles stored in the file."
    end
    buffer = Base.RefValue{P}()
    EGSPhspIterator(io, h, buffer, len)
end

function Base.iterate(iter::EGSPhspIterator)
    # skip header
    pos = sizeof(ptype(iter.header))
    seek(iter.io, pos)
    _iterate(iter)
end

@inline function _iterate(iter::EGSPhspIterator)
    if eof(iter.io)
        nothing
    else
        p = read!(iter.io, iter.buffer)[]
        dummy_state = nothing
        p, dummy_state
    end
end

zlast_type(P::Type{EGSParticle{ZLAST}}) where {ZLAST} = ZLAST
zlast_type(p::EGSParticle{ZLAST}) where {ZLAST} = ZLAST
zlast_type(o) = zlast_type(ptype(o))

function write_header(io::IO, h::EGSHeader)
    ZLAST = zlast_type(h)
    mode = if ZLAST == Nothing
        "MODE0"
    else
        @assert ZLAST == Float32
        "MODE2"
    end

    ret = 0
    ret += write(io, mode)
    ret += write(io, h.particlecount)
    ret += write(io, h.photoncount)
    ret += write(io, h.max_E_kin)
    ret += write(io, h.min_E_kin_electrons)
    ret += write(io, h.originalcount)
    psize = sizeof(ptype(h))
    while (ret < psize)
        ret += write(io, '\0')
    end
    @assert ret == psize
    ret
end

mutable struct EGSWriter{P <: EGSParticle, I <: IO}
    io::I
    particlecount::Int32
    photoncount::Int32
    max_E_kin::Float32
    min_E_kin_electrons::Float32
    originalcount::Float32
    buffer::Base.RefValue{P}
    function EGSWriter{P}(io::I, particlecount, photoncount,
                       max_E_kin, min_E_kin_electrons,
                       originalcount, buffer) where {P,I}

        w = new{P,I}(io, particlecount, photoncount,
                       max_E_kin, min_E_kin_electrons,
                       originalcount, buffer)
        finalizer(close, w)
        w
    end
end

function Base.write(w::EGSWriter{P}, p::P) where {P <: EGSParticle}
    w.particlecount += 1
    if isphoton(p)
        w.photoncount += 1
    end
    w.max_E_kin = max(w.max_E_kin, p.E)
    if iselectron(p)
        w.min_E_kin_electrons = min(w.min_E_kin_electrons, p.E)
    end
    w.buffer[] = p
    write(w.io, w.buffer)
end

function create_header(w::EGSWriter{P}) where {P}
    h = EGSHeader{P}(
        w.particlecount::Int32,
        w.photoncount::Int32,
        w.max_E_kin::Float32,
        w.min_E_kin_electrons::Float32,
        w.originalcount::Float32,
   )
end

function egs_writer(f, path, P)
    w = egs_writer(path, P)
    ret = call_fenced(f,w)
    close(w)
    ret
end

function egs_writer(path::AbstractString, P)
    io = open(path, "w")
    egs_writer(io, P)
end

function egs_writer(io::IO, ::Type{P}) where {P <: EGSParticle}
    buffer = Base.RefValue{P}()
    w = EGSWriter{P}(io, Int32(0),Int32(0),Float32(-Inf),Float32(Inf),Float32(1.), buffer)
    h = create_header(w)
    write_header(io, h)
    w
end

function Base.flush(w::EGSWriter)
    if isopen(w.io)
        h = create_header(w)
        pos = position(w.io)
        seekstart(w.io)
        write_header(w.io, h)
        seek(w.io, pos)
    end
    flush(w.io)
end

function Base.close(w::EGSWriter)
    flush(w)
    close(w.io)
end
