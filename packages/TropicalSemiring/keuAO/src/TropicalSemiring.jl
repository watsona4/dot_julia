__precompile__()

module TropicalSemiring

export Trop, Min, Max, inf

import Base: +, *, ==, ^, -

"""
    Min

Indicating that we are in the tropical semiring ``(ℝ ∪ {∞}, ⊕, ⊙)`` with the
min convention.
"""
struct Min end

"""
    Max

Indicating that we are in the tropical semiring ``(ℝ ∪ {-∞}, ⊕, ⊙)`` with the
max convention.
"""
struct Max end

const MinMax = Union{Min, Max}

"""
    Trop{MM<:MinMax, T<:Real}

A `Trop` number is an element of a the tropical semi-ring. These come in two
flavours `Max` and `Min`. In the `Max` case this is the semi-ring ``(ℝ ∪ {-∞}, ⊕, ⊙)`` where
``⊕`` is the usual multiplication and ``⊙`` is the usual maximum.
In the `Min` case this is the semi-ring ``(ℝ ∪ {∞}, ⊕, ⊙)`` where
``⊕`` is the usual multiplication and ``⊙`` is the usual minimum.
"""
struct Trop{MM<:MinMax, T<:Real} <: Number
    val::T
    isinf::Bool
end
Trop{MM, T}(x::Real) where {T<:Real, MM<:MinMax} = Trop{MM, T}(convert(T, x), false)
Trop{MM}(x::T, isinf=false) where {T<:Real, MM<:MinMax} = Trop{MM, T}(x, isinf)
Trop(x::Real, isinf=false) = Trop{Max}(x, isinf)

Base.isinf(x::Trop) = x.isinf

function (+)(a::Trop{Max, T}, b::Trop{Max, T}) where {T<:Real}
    Trop{Max}(max(a.val, b.val), isinf(a) || isinf(b))
end
function (+)(a::Trop{Min, T}, b::Trop{Min, T}) where {T<:Real}
    Trop{Min}(min(a.val, b.val), isinf(a) || isinf(b))
end

# this doesn't make sense, but we define it nonetheless to make
# MultivariatePolynomials happy
(-)(a::Trop) = a

function (*)(a::Trop{MM, T}, b::Trop{MM, T}) where {MM<:MinMax, T<:Real}
    Trop{MM}(a.val + b.val, isinf(a) || isinf(b))
end

function (^)(a::Trop{MM, T}, p::Integer) where {MM<:MinMax, T<:Real}
    Trop(convert(T, p) * a.val, isinf(a))
end

function Base.isequal(a::Trop{M, T}, b::Trop{M, S}) where {M, S, T}
    isinf(a) || isinf(b) ? isinf(a) == isinf(b) : a.val == b.val
end
Base.isequal(a::Trop{Min, T}, b::Trop{Max, S}) where {S, T} = false
Base.isequal(a::Trop{Max, T}, b::Trop{Min, S}) where {S, T} = false

(==)(a::Trop, b::Trop) = isequal(a,b)

Base.one(::Trop{MM, T}) where {MM, T} = Trop{MM}(zero(T))
Base.one(::Type{Trop{MM, T}}) where {MM, T} = Trop{MM}(zero(T))

Base.zero(::Trop{MM, T}) where {MM, T} = Trop{MM}(zero(T), true)
Base.zero(::Type{Trop{MM, T}}) where {MM, T} = Trop{MM}(zero(T), true)

function Base.show(io::IO, a::Trop{MM, T}) where {MM, T}
    if isinf(a)
        if MM === Max
            print(io, "∞")
        else
            print(io, "-∞")
        end
    else
        print(io, a.val)
    end
end

function Base.promote_rule(::Type{Trop{MM, T}}, ::Type{Trop{MM, S}}) where {MM, S,T}
    Trop{MM, promote_type(S,T)}
end

function Base.convert(::Type{Trop{MM, T}}, t::Trop{MM, S}) where {MM, T<:Real, S<:Real}
    Trop{MM}(convert(T, t.val), t.isinf)
end

"""
    inf(M::Type{<:Union{Min, Max}} = Max)

Constructs ``-∞`` in the case of `Max` and ``∞`` in the case of `Min`.
"""
inf(minmax::Type{M}=Max) where {M<:MinMax} = Trop{M}(true, true)

end # module
