export EntropyConeLift, equalonsubsetsof!, equalvariable!

mutable struct EntropyConeLift{T<:Real} <: AbstractEntropyCone{T}
    n::Vector{Int}
    poly::Polyhedron{T}

    function EntropyConeLift{T}(n::Vector{Int}, poly::Polyhedron{T}) where {T}
        new{T}(n, poly)
    end

    function EntropyConeLift{T}(n::Vector{Int}, A::AbstractMatrix{T}, equalities::BitSet) where {T}
        if sum(ntodim(n)) != size(A, 2)
            error("The dimensions in n does not agree with the number of columns of A")
        end
        if !isempty(equalities) && last(equalities) > size(A, 1)
            error("Equalities should range from 1 to the number of rows of A")
        end
        ine = hrep(A, spzeros(T, size(A, 1)), equalities)
        new{T}(n, polyhedron(ine))
    end

end

Polyhedra.fulldim(h::EntropyConeLift) = Int(sum(ntodim(h.n)))

EntropyConeLift(n::Vector{Int}, A::AbstractMatrix{T}) where {T<:Real} = EntropyConeLift(n, A, BitSet())

Base.convert(::Type{EntropyConeLift{S}}, H::EntropyConeLift{T}) where {S<:Real,T<:Real} = EntropyConeLift{S}(H.n, Polyhedron{S}(H.poly))

Base.convert(::Type{EntropyConeLift{T}}, h::EntropyCone{T}) where {T<:Real} = EntropyConeLift([h.n], h.poly)

#Base.getindex{T<:Real}(H::EntropyConeLift{T}, i) = DualEntropyLift(H.n, H.A[i,:], i in H.equalities)

function offsetfor(h::EntropyConeLift, id::Integer)
    id == 1 ? 0 : sum(map(ntodim, h.n[1:(id-1)]))
end
function indset(h::AbstractEntropyCone, id::Integer)
    indset(h.n[id])
end
function rangefor(h::EntropyConeLift, id::Integer)
    offset = offsetfor(h, id)
    offset .+ indset(h, id)
end

promote_rule(::Type{EntropyConeLift{T}}, ::Type{EntropyCone{T}}) where {T<:Real} = EntropyConeLift{T}

function (*)(x::AbstractEntropyCone{T}, y::AbstractEntropyCone{T}) where {T<:Real}
    # A = [x.A zeros(T, size(x.A, 1), N2); zeros(T, size(y.A, 1), N1) y.A]
    # equalities = copy(x.equalities)
    # for eq in y.equalities
    #   push!(equalities, size(x.A, 1) + eq)
    # end
    EntropyConeLift{T}([x.n; y.n], x.poly * y.poly)
end

function equalonsubsetsof!(H::EntropyConeLift{T}, id1, id2, S::EntropyIndex, I::EntropyIndex=emptyset(), σ=collect(1:H.n[id1])) where {T}
    if S == emptyset()
        return
    end
    nrows = (1<<(card(S)))-1
    A = spzeros(T, nrows, Polyhedra.fulldim(H))
    cur = 1
    offset1 = offsetfor(H, id1)
    offset2 = offsetfor(H, id2)
    for K in setsto(S)
        if K ⊆ S && !(K ⊆ I)
            A[cur, offset1+K] = 1
            A[cur, offset2+mymap(σ, K, H.n[id2])] = -1
            cur += 1
        end
    end
    ine = MixedMatHRep(A, spzeros(T, nrows), BitSet(1:nrows))
    intersect!(H, ine)
end
equalonsubsetsof!(H::EntropyConeLift, id1, id2, s::Signed) = equalonsubsetsof!(H, id1, id2, set(s))

function equalvariable!(h::EntropyConeLift{T}, id::Integer, i::Signed, j::Signed) where {T}
    if id < 1 || id > length(h.n) || min(i,j) < 1 || max(i,j) > h.n[id]
        error("invalid")
    end
    if i == j
        @warn "useless"
        return
    end
    nrows = 1 << (h.n[id]-1)
    A = spzeros(T, nrows, Polyhedra.fulldim(h))
    offset = offsetfor(h, id)
    cur = 1
    for S in indset(h, id)
        if myin(i, S)
            A[cur, offset+S] = 1
            Q = union(setdiff(S, set(i)), set(j))
            A[cur, offset+Q] = -1
            cur += 1
        end
    end
    intersect!(h, MixedMatHRep(A, spzeros(T, nrows), BitSet(1:nrows)))
end

ninneradh(n, J::EntropyIndex, K::EntropyIndex) = n
nselfadh(n, J::EntropyIndex, I::EntropyIndex) = n + card(setdiff(J, I))
nadh(n, J::EntropyIndex, K::EntropyIndex, adh::Type{Val{:Inner}}) = ninneradh(n, J, K)
nadh(n, J::EntropyIndex, K::EntropyIndex, adh::Type{Val{:Self}}) = nselfadh(n, J, K)
nadh(n, J::EntropyIndex, K::EntropyIndex, adh::Type{Val{:NoAdh}}) = n
nadh(n, J::EntropyIndex, K::EntropyIndex, adh::Symbol) = nadh(n, J, K, Val{adh})

function inneradhesivelift(h::EntropyCone{T}, J::EntropyIndex, K::EntropyIndex) where {T}
    cur = polymatroidcone(T, ninneradh(h.n, J, K))
    intersect!(cur, submodulareq(cur.n, J, K))
    lift = h * cur
    I = J ∩ K
    equalonsubsetsof!(lift, 1, 2, J)
    equalonsubsetsof!(lift, 1, 2, K, I)
    lift
end
function selfadhesivelift(h::EntropyCone{T}, J::EntropyIndex, I::EntropyIndex) where {T}
    newn = nselfadh(h.n, J, I)
    K = setdiff(fullset(newn), fullset(h.n)) ∪ I
    cur = polymatroidcone(T, newn)
    intersect!(cur, submodulareq(cur.n, fullset(h.n), K, I))
    lift = h * cur
    equalonsubsetsof!(lift, 1, 2, fullset(h.n))
    themap = Vector{Int}(undef, h.n)
    cur = h.n
    for i in 1:h.n
        if myin(i, I)
            themap[i] = i
        elseif myin(i, J)
            cur += 1
            themap[i] = cur
        else
            themap[i] = -1
        end
    end
    @assert cur == newn
    equalonsubsetsof!(lift, 1, 2, J, I, themap)
    lift
end
adhesivelift(h::EntropyCone, J::EntropyIndex, K::EntropyIndex, adh::Type{Val{:Inner}}) = inneradhesivelift(h, J, K)
adhesivelift(h::EntropyCone, J::EntropyIndex, K::EntropyIndex, adh::Type{Val{:Self}}) = selfadhesivelift(h, J, K)
adhesivelift(h::EntropyCone, J::EntropyIndex, K::EntropyIndex, adh::Symbol) = adhesivelift(h, J, K, Val{adh})
