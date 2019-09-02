
###### legacy codes
function simplify(c::Char)
    return c
end

function ==(a::HiddenMarkovModel{Tv, Ti}, b::HiddenMarkovModel{Tv, Ti}) where {Tv, Ti}
    res = true
    for fname in fieldnames(HiddenMarkovModel{Tv, Ti})
        res &= getfield(a, fname) == getfield(b, fname)
    end
    return res
end


function write(io::IO, obj::HiddenMarkovModel{Tv, Ti}) where {Tv, Ti}
    nbit = 0
    nbit += write(io, sizeof(Tv))
    if Ti isa Unsigned
        nbit += write(io, +1)
    else
        nbit += write(io, -1)
    end
    nbit += write(io, sizeof(Ti))
    nbit += write(io, obj.aca)
    for p in obj.pos
        nbit += write(io, p, " ")
    end
    nbit += write(io, "\n")
    nbit += write(io, obj.hpr)
    nbit += write(io, obj.h2h)
    for vp in obj.h2v
        nbit += write(io, length(vp))
        for (v, p) in vp
            nbit += write(io, v)
            nbit += write(io, p)
        end
    end
    nbit += write(io, obj.MAX)
    nbit += write(io, obj.sumhpr)
    nbit += write(io, obj.sumh2hdim1)
    nbit += write(io, obj.sumh2vdimv)
    return nbit
end

function nbit2type(nbit, types)
    filter(x -> sizeof(x) == nbit, types)[1]
end

function read(io::IO, obj::Type{HiddenMarkovModel})
    Tv = nbit2type(read(io, Int), [Float32, Float64])
    sign = read(io, Int)
    Ti = Int
    if sign > 0
        Ti = nbit2type(read(io, Int), [UInt8, UInt16, UInt32, UInt64])
    else
        Ti = nbit2type(read(io, Int), [Int8, Int16, Int32, Int64])
    end
    aca = read(io, AhoCorasickAutomaton)
    pos = split(readline(io))
    npos = length(pos)
    hpr = reinterpret(Tv, read(io, npos * sizeof(Tv)))
    h2h = reshape(reinterpret(Tv, read(io, npos * npos * sizeof(Tv))), (npos, npos))
    h2v = Vector{Dict{Int, Tv}}(undef, npos)
    for i = 1:npos
        vps = Dict{Int, Tv}()
        nv = read(io, Int)
        for j = 1:nv
            v = read(io, Int)
            p = read(io, Tv)
            vps[v] = p
        end
        h2v[i] = vps
    end
    MAX    = read(io, Tv)
    sumhpr = read(io, Tv)
    sumh2hdim1 = reshape(reinterpret(Tv, read(io, npos * sizeof(Tv))), 1, npos)
    sumh2vdimv = reinterpret(Tv, read(io, npos * sizeof(Tv)))
    return HiddenMarkovModel{Tv, Ti}(aca, pos, hpr, h2h, h2v, MAX, sumhpr, sumh2hdim1, sumh2vdimv)
end
function h2v(obj::HiddenMarkovModel{Tv, Ti}, h::String, v::String) where Tv where Ti
    ih = findfirst(isequal(h), obj.pos)
    iv = get(obj.aca, v, Ti(0))
    return get(obj.h2v[ih], iv, obj.alpha[ih])
end

function h2h(obj::HiddenMarkovModel{Tv, Ti}, pos1::String, pos2::String) where Tv where Ti
    i1 = findfirst(isequal(pos1), obj.pos)
    i2 = findfirst(isequal(pos2), obj.pos)
    return obj.h2h[i2, i1]
end

function norm!(hpr::Vector{Tv}) where Tv
    tot = sum(hpr)
    @assert !isinf(tot)
    hpr .= -log.(hpr ./ tot)
    return tot
end

function norm!(h2h::Matrix{Tv}) where Tv
    sum1 = sum(h2h; dims = 1)
    h2h .= -log.(h2h ./ sum1)
    return sum1
end

function norm!(h2v::Vector{Dict{Int, Tv}}) where Tv
    sumv = Vector{Tv}(undef, length(h2v))
    for (ih, vs) in enumerate(h2v)
        tot = sum(values(vs))
        sumv[ih] = tot
        for v in keys(vs)
            vs[v] = -log(vs[v]) + log(tot)
        end
    end
    return sumv
end

function denorm!(hpr::Vector{Tv}, sumhpr::Tv) where Tv
    return hpr .= exp.(.-hpr) .* sumhpr
end

function denorm!(h2h::Matrix{Tv}, sumh2hdim1::Matrix{Tv}) where Tv
    return h2h .= exp.(.-h2h) .* sumh2hdim1
end

function denorm!(h2v::Vector{Dict{Int, Tv}}, sumh2vdimv::Vector{Tv}) where Tv
    for (h, vs) in enumerate(h2v)
        for (v, p) in vs
            vs[v] = exp(-p) * sumh2vdimv[h]
        end
    end
    return h2v
end

function stat(obj::HiddenMarkovModel{Tv, Ti}) where {Tv, Ti}
    res = Vector()
    dict = map(first, sort!(collect(obj.aca); by = last))
    hpr = copy(obj.hpr)
    denorm!(hpr, obj.sumhpr)
    for i = 1:length(obj.pos)
        pos = obj.pos[i]
        nhead = round(Int, hpr[i])
        tot = round(Int, obj.sumh2vdimv[i])
        vs  = sort!(collect(obj.h2v[i]); by = last, rev = true)
        vs = map(x -> dict[x[1]], vs)
        push!(res, (pos = pos, nhead = nhead, tot = tot, vs = vs))
    end
    return res
end
