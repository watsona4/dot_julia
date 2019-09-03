struct Polynomial{N, T} <: AbstractPolynomial{N, T}
    coeffs::NTuple{N, T}
end

# Construction
Polynomial(coeffs::Tuple) = Polynomial(promote(coeffs...))
Polynomial(coeffs...) = Polynomial(coeffs)

@inline function Polynomial{N, T}(p::Polynomial{M, S}) where {N, T, M, S}
    if N < M
        for i in N + 1 : M
            iszero(p.coeffs[i]) || throw(InexactError(:Polynomial, Polynomial{N}, p))
        end
        coeffs = ntuple(Val(N)) do i
            p.coeffs[i]
        end
        return Polynomial(coeffs)
    else
        coeffs = (
            _map(x -> convert(T, x), p.coeffs)...,
            ntuple(_ -> zero(T), Val(N - M))...
        )
        return Polynomial(coeffs)
    end
end

Polynomial{N}(p::Polynomial{M, T}) where {N, M, T} = Polynomial{N, T}(p)

# Utility
constant(p::Polynomial) = p.coeffs[1]
Base.zero(::Type{Polynomial{N, T}}) where {N, T} = Polynomial(ntuple(_ -> zero(T), Val(N)))
Base.zero(p::Polynomial) = zero(typeof(p))
Base.conj(p::Polynomial) = Polynomial(map(conj, p.coeffs))
Base.transpose(p::Polynomial) = p

# Evaluation
(p::Polynomial{1})(x) = p.coeffs[1] # evalpoly doesn't handle N = 1 case
@generated function (p::Polynomial{N})(x) where N
    quote
        coeffs = p.coeffs
        @evalpoly(x, $((:(p.coeffs[$i]) for i = 1 : N)...))
    end
end

# Arithmetic
for op in [:+, :-]
    @eval begin
        # Two Polynomials
        function Base.$op(p1::Polynomial{N}, p2::Polynomial{N}) where N
            c1 = p1.coeffs
            c2 = p2.coeffs
            Polynomial(_map($op, c1, c2))
        end
        function Base.$op(p1::Polynomial{N}, p2::Polynomial{M}) where {N, M}
            P = max(N, M)
            $op(Polynomial{P}(p1), Polynomial{P}(p2))
        end

        # Polynomial and Number
        Base.$op(p::Polynomial, c::Number) = Polynomial($op(constant(p), c), Base.tail(p.coeffs)...)
        Base.$op(c::Number, p::Polynomial) = Polynomial($op(c, constant(p)), map($op, Base.tail(p.coeffs))...)

        # Unary ops
        Base.$op(p::Polynomial) = Polynomial(map($op, p.coeffs))
    end
end

@generated function Base.:*(p1::Polynomial{M}, p2::Polynomial{N}) where {M, N}
    P = M + N - 1
    exprs = Any[nothing for i = 1 : P]
    for i in 1 : M
        for j in 1 : N
            k = i + j - 1
            if exprs[k] === nothing
                exprs[k] = :(p1.coeffs[$i] * p2.coeffs[$j])
            else
                exprs[k] = :(muladd(p1.coeffs[$i], p2.coeffs[$j], $(exprs[k])))
            end
        end
    end
    return quote
        Base.@_inline_meta
        Polynomial(tuple($(exprs...)))
    end
end

for op in [:*, :/]
    @eval Base.$op(p::Polynomial, c::Number) = Polynomial(_map(x -> $op(x, c), p.coeffs))
end
Base.:*(c::Number, p::Polynomial) = Polynomial(_map(x -> c * x, p.coeffs))

# Calculus
"""
    derivative(p::Polynomial)

Return the derivative of ``p(x)`` with respect to ``x`` as a `Polynomial`.
"""
function derivative end

derivative(p::Polynomial{1}) = Polynomial(zero(p.coeffs[1]))
function derivative(p::Polynomial{N}) where N
    ntuple(Val(N - 1)) do i
        i * p.coeffs[i + 1]
    end |> Polynomial
end

"""
    integral(p::Polynomial, c)

Return ``P(x)``, the integral of ``p(x)`` with respect to ``x`` such that ``P(0) = c``,
as a `Polynomial`.
"""
function integral(p::Polynomial{N}, c) where N
    tail = ntuple(Val(N)) do i
        p.coeffs[i] / i
    end
    T = eltype(tail)
    Polynomial((T(c), tail...))
end

# Gradient w.r.t coefficients
"""
    coefficient_gradient(x, ::Val{n}, ::Val{m}) where {n, m}

Return the gradient of the `m`th derivative of an `n`-coefficient polynomial, evaluated at `x`,
with respect to the polynomial's coefficients, as a `Tuple`.
"""
function coefficient_gradient(x, ::Val{num_coeffs}, ::Val{deriv_order}=Val(0)) where {num_coeffs, deriv_order}
    num_coeffs >= 0 || error()
    deriv_order >= 0 || error()
    first(_coefficient_gradient(x, Val(num_coeffs), Val(deriv_order)))
end

_coefficient_gradient(x, ::Val{0}, ::Val) = (), one(x)
Base.@pure @inline function _coefficient_gradient(x, ::Val{num_coeffs}, ::Val{deriv_order}) where {num_coeffs, deriv_order}
    previous, xpow = _coefficient_gradient(x, Val(num_coeffs - 1), Val(deriv_order))
    multiplier = prod((num_coeffs - deriv_order) : num_coeffs - 1)
    (previous..., multiplier * xpow), num_coeffs > deriv_order ? xpow * x : xpow
end
