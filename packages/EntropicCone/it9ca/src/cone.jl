import Polyhedra.fulldim
export EntropyCone, polymatroidcone, redundant, getinequalities, getextremerays, tight!

# Entropy Cone

abstract type AbstractEntropyCone{T<:Real} end

Polyhedra.fulldim(h::AbstractEntropyCone) = Polyhedra.fulldim(h.poly)

mutable struct EntropyCone{T<:Real} <: AbstractEntropyCone{T}
    n::Int
    poly::Polyhedron{T}

    function EntropyCone{T}(n::Int, p::Polyhedron{T}) where T
        if ntodim(n) != Polyhedra.fulldim(p)
            error("The number of variables does not match the dimension of the polyhedron")
        end
        new{T}(n, p)
    end
end
EntropyCone(n::Int, p::Polyhedron{T}) where {T} = EntropyCone{T}(n, p)

#EntropyCone{T<:AbstractFloat}(n::Int, A::AbstractMatrix{T}) = EntropyCone{Float64}(n, AbstractMatrix{Float64}(A), BitSet([]))
#EntropyCone{T<:Real}(n::Int, A::AbstractMatrix{T}) = EntropyCone{Rational{BigInt}}(n, AbstractMatrix{Rational{BigInt}}(A), BitSet())

#Base.getindex{T<:Real}(H::EntropyCone{T}, i) = DualEntropy(H.n, H.A[i,:], i in H.equalities) # FIXME

Base.copy(h::EntropyCone{T}) where {T<:Real} = EntropyCone{T}(h.n, copy(h.poly))

function indset(h::EntropyCone)
    indset(h.n)
end

function getinequalities(h::EntropyCone)
    removeredundantinequalities!(h.poly)
    ine = getinequalities(h.poly)
    if sum(abs(ine.b)) > 0
        error("Error: b is not zero-valued.")
    end
    [DualEntropy(ine.A[i,:], i in ine.linset) for i in 1:size(ine.A, 1)]
end

function getextremerays(h::EntropyCone)
    removeredundantgenerators!(h.poly)
    ext = SimpleVRepresentation(getgenerators(h.poly))
    if size(ext.V, 1) > 0
        error("Error: There are vertices.")
    end
    [PrimalEntropy(ext.R[i,:]) for i in 1:size(ext.R, 1)]
end

function Base.intersect!(H::AbstractEntropyCone, h::AbstractDualEntropy{L}) where {L}
    @assert Polyhedra.fulldim(H) == Polyhedra.fulldim(h)
    if H.n != h.n
        error("The dimension of the cone and entropy differ")
    end
    intersect!(H.poly, hrep(h))
end
function Base.intersect!(H::EntropyCone, hs::Vector{<:DualEntropy{L}}) where {L}
    @assert all(Polyhedra.fulldim(H) == Polyhedra.fulldim(h) for h in hs)
    intersect!(H.poly, hrep(hs))
end

function Base.intersect!(h::AbstractEntropyCone, hr::HRepresentation)
    h.poly = intersect(h.poly, hr)
end
function Base.intersect!(h1::AbstractEntropyCone, h2::AbstractEntropyCone)
    if h1.n != h2.n
        error("The dimension for the cones differ")
    end
    intersect!(h1.poly, h2.poly)
end

function Base.intersect(h1::AbstractEntropyCone, h2::AbstractEntropyCone)
    if h1.n != h2.n
        error("The dimension for the cones differ")
    end
    typeof(h1)(h1.n, intersect(h1.poly, h2.poly))
end

function polymatroidcone(::Type{T}, n::Integer, lib = nothing, minimal = true) where T
    # 2^n-1           nonnegative   inequalities H(S) >= 0
    # n*2^(n-1)-n     nondecreasing inequalities H(S) >= H(T) https://oeis.org/A058877
    # n*(n+1)*2^(n-2) submodular    inequalities              https://oeis.org/A001788

    # Actually, nonnegative is not required and nondecreasing only for H([n]) and H([n] \ i)
    n_nonnegative   = minimal ? 0 : 2^n-1
    n_nondecreasing = minimal ? n : n*2^(n-1)-n
    n_submodular    = 0
    if n >= 3
        n_submodular  = (n-1)*n*2^(n-3)
    elseif n == 2
        n_submodular  = 1
    end
    offset_nonnegative   = 0
    offset_nondecreasing = n_nonnegative
    offset_submodular    = n_nonnegative + n_nondecreasing
    cur_nonnegative   = 1
    cur_nondecreasing = 1
    cur_submodular    = 1
    HT = HalfSpace{T, SparseVector{T, Int}}
    hss = Vector{HT}(undef, n_nonnegative + n_nondecreasing + n_submodular)
    for j = 1:n
        for k = (j+1):n
            hss[offset_submodular+cur_submodular] = HRepElement(submodular(n, set(j), set(k)))
            cur_submodular += 1
        end
    end
    for I = indset(n)
        if !minimal
            hss[offset_nonnegative+cur_nonnegative] = HRepElement(nonnegative(n, I))
            cur_nonnegative += 1
        end
        for j = 1:n
            if !myin(j, I)
                if !minimal || card(I) == n-1
                    hss[offset_nondecreasing+cur_nondecreasing] = HRepElement(nondecreasing(n, I, set(j)))
                    cur_nondecreasing += 1
                end
                for k = (j+1):n
                    if !myin(k, I)
                        hss[offset_submodular+cur_submodular] = HRepElement(submodular(n, set(j), set(k), I))
                        cur_submodular += 1
                    end
                end
            end
        end
    end
    @assert cur_nonnegative == n_nonnegative+1
    @assert cur_nondecreasing == n_nondecreasing+1
    @assert cur_submodular == n_submodular+1
    h = hrep(hss)
    if lib === nothing
        p = polyhedron(h)
    else
        p = polyhedron(h, lib)
    end
    EntropyCone(n, p)
end
polymatroidcone(n::Integer, lib = nothing, minimal = true) = polymatroidcone(Int, n, lib, minimal)

function tight!(h::EntropyCone)
    tightness = DualEntropy{Int}[setequality(nondecreasing(h.n, setdiff(fullset(h.n), set(i)), set(i))) for i in 1:h.n]
    intersect!(h, tightness)
end
