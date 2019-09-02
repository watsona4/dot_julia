export phsp_iterator
export iaea_iterator
export iaea_writer
export egs_iterator
export egs_writer
export egs_write
export iaea_write
export phsp_write

function iaea_writer end

iaea_iterator(path) = iaea_iterator(IAEAPath(path))

function iaea_iterator(path::IAEAPath)
    @argcheck ispath(path.header)
    @argcheck ispath(path.phsp)
    h = load(path.header, IAEAHeader)
    io = FastReadIO(open(path.phsp))
    IAEAPhspIterator(io,h)
end

function egs_iterator(path::AbstractString)
    io = open(path, "r")
    egs_iterator(io)
end

phsp_iterator(path::IAEAPath) = iaea_iterator(path)
function phsp_iterator(path::AbstractString)
    stem, ext = splitext(path)
    if startswith(ext, ".IAEA")
        iaea_iterator(path)
    elseif startswith(ext, ".egsphsp")
        egs_iterator(path)
    else
        msg = "Cannot guess format from file extension for $path."
        throw(ArgumentError(msg))
    end
end

for xxx_iterator in [:egs_iterator, :iaea_iterator, :phsp_iterator]
    @eval function $(xxx_iterator)(f, path)
        iter = $(xxx_iterator)(path)
        ret = call_fenced(f, iter)
        close(iter)
        ret
    end
end

function _iaea_header_like(P::Type{IAEAParticle{Nf, Ni}}) where {Nf, Ni}
    r = IAEAHeader{Nf, Ni}()
end

function iaea_write(path, ps)
    r = _iaea_header_like(eltype(ps))
    iaea_writer(path,r) do w
        for p in ps
            write(w, p)
        end
    end
end

function egs_write(path, ps)
    P = eltype(ps)
    egs_writer(path, P) do w
        for p in ps
            write(w, p)
        end
    end
end

function phsp_write(path, ps)
    P = eltype(ps)
    if P <: IAEAParticle
        iaea_write(path, ps)
    elseif P <: EGSParticle
        egs_write(path, ps)
    else
        msg = "Cannot guess format from eltype(ps) = $P."
        throw(ArgumentError(msg))
    end
end
