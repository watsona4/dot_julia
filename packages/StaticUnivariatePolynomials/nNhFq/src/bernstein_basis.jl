
struct BernsteinPolynomial{N, T} <: AbstractPolynomial{N, T}
    coeffs::NTuple{N, T}
end

# Construction
BernsteinPolynomial(coeffs::Tuple) = BernsteinPolynomial(promote(coeffs...))
BernsteinPolynomial(coeffs...) = BernsteinPolynomial(coeffs)

# Conversion to monomial basis
Polynomial(b::BernsteinPolynomial{1}) = Polynomial(b.coeffs)
function Polynomial(b::BernsteinPolynomial{N, T}) where {N, T}
    # b(t) = (1 - t) * b1(t) + t * b2(t)
    #      = b1(t) + t * (b2(t) - b1(t))
    b1 = BernsteinPolynomial(reverse(tail(reverse(b.coeffs))))
    b2 = BernsteinPolynomial(tail(b.coeffs))
    Polynomial(b1) + Polynomial(0, 1) * Polynomial(b2 - b1)
end

# Utility
@inline constant(b::BernsteinPolynomial) = b.coeffs[1]
Base.zero(::Type{BernsteinPolynomial{N, T}}) where {N, T} = BernsteinPolynomial(ntuple(_ -> zero(T), Val(N)))
Base.zero(b::BernsteinPolynomial) = zero(typeof(b))

# Evaluation
@inline (b::BernsteinPolynomial{1})(t) = constant(b)
@inline function (b::BernsteinPolynomial)(t)
    b1 = BernsteinPolynomial(reverse(tail(reverse(b.coeffs))))
    b2 = BernsteinPolynomial(tail(b.coeffs))
    (oneunit(t) - t) * b1(t) + t * b2(t)
end

for op in [:+, :-]
    @eval begin
        # Two BernsteinPolynomials
        Base.$op(b1::BernsteinPolynomial{N}, b2::BernsteinPolynomial{N}) where {N} = BernsteinPolynomial(_map($op, b1.coeffs, b2.coeffs))

        # BernsteinPolynomials and constant
        Base.$op(b::BernsteinPolynomial, c) = BernsteinPolynomial(_map(p -> $op(p, c), b.coeffs))
        Base.$op(c, b::BernsteinPolynomial) = BernsteinPolynomial(_map(p -> $op(c, p), b.coeffs))
    end
end

for op in [:*, :/]
    @eval Base.$op(b::BernsteinPolynomial, c) = BernsteinPolynomial(_map(x -> $op(x, c), b.coeffs))
end
Base.:*(c, b::BernsteinPolynomial) = BernsteinPolynomial(_map(x -> c * x, b.coeffs))

@inline function derivative(b::BernsteinPolynomial{N}) where {N}
    # https://pages.mtu.edu/~shene/COURSES/cs3621/NOTES/spline/Bezier/bezier-der.html
    coeffs = b.coeffs
    n = N - 1
    BernsteinPolynomial(ntuple(i -> n * (coeffs[i + 1] - coeffs[i]), n))
end


"""
```math
\\int_{0}^{1} b\\left(\\tau\\right) e^{c \\tau} d\\tau
```
"""
@inline function exponential_integral(b::BernsteinPolynomial{N}, c; inv_c=inv(c), exp_c=exp(c)) where N
    pn = b.coeffs[N]
    if N === 1
        return inv_c * constant(b) * (exp_c - 1)
    else
        return inv_c * (pn * exp_c - constant(b) - exponential_integral(derivative(b), c, inv_c=inv_c, exp_c=exp_c))
    end
end
