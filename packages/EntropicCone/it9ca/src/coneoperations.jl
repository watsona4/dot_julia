import Polyhedra.polyhedron
# Fullin also provides a certificate so it is interesting so it is exported
export getextremerays, fullin

function unlift(h::EntropyConeLift)
    poly = getpoly(h)
    EntropyCone(eliminate(poly, [(ntodim(h.n[1])+1):Polyhedra.fulldim(h)]))
end

function fullin(h::AbstractPrimalEntropy, H::AbstractEntropyCone)
    Ray(h.h) in H.poly
    #all(H.A*h.h .>= 0)
end
function partialin(h::AbstractPrimalEntropy{S}, H::AbstractEntropyCone{T}) where {S, T}
    hps = HyperPlane{T, SparseVector{T, Int}}[]
    offseth = 0
    offsetsH = [0; cumsum(map(ntodim, H.n))]
    for i in eachindex(collect(h.n)) # use of collect in case h.n is scalar
        for j in indset(h, i)
            col = offsetsH[h.liftid[i]]+j
            push!(hps, HyperPlane(sparsevec([col], [one(T)], Polyhedra.fulldim(H)), T(h.h[offseth+j])))
        end
        offseth += ntodim(h.n[i])
    end
    !isempty(H.poly ∩ hrep(hps))
end

function Base.in(h::PrimalEntropy, H::EntropyCone)
    if Polyhedra.fulldim(h) > Polyhedra.fulldim(H)
        error("The vector has a higher dimension than the cone")
    elseif Polyhedra.fulldim(h) == Polyhedra.fulldim(H)
        fullin(h, H)[1]
    else
        partialin(h, H)
    end
end

function Base.in(h::PrimalEntropyLift, H::EntropyConeLift)
    if length(h.n) > length(H.n) || any(h.n .> H.n)
        error("The vector has a higher dimension than the cone")
    elseif h.n == H.n
        fullin(h, H)[1]
    else
        partialin(h, H)
    end
end

function Base.in(h::PrimalEntropy, H::EntropyConeLift)
    if h.liftid < 1 || h.liftid > length(H.n) || h.n > H.n[h.liftid]
        error("The vector has a higher dimension than the cone")
    elseif h.n == H.n
        fullin(h, H)[1]
    else
        partialin(h, H)
    end
end

#function redundant(h::AbstractDualEntropy{L, S}, H::AbstractEntropyCone{T}) where {L, S, T}
#    (isin, certificate, vertex) = ishredundant(H.poly, HRepElement(h))
#    (isin, certificate, vertex)
#end

Base.in(h::DualEntropy, H::EntropyCone) = H.poly ⊆ HRepElement(h)

Base.in(h::DualEntropyLift, H::EntropyConeLift) = H.poly ⊆ HRepElement(h)

function Base.in(h::DualEntropy, H::EntropyConeLift)
    Base.in(DualEntropyLift(h, length(H.n)), H)
end
