#

"""
    `as_poly(f)` convert something into a polynomial

Here `f` can be a `Polynomial` object; a vector of coefficents in the
form `[a_0, a_1, ..., a_n]`; or a callable object, such as a function,
that implements a polynomial function. The latter is determined by whether
it can be evaluated on the `Polynomial` monomial `x`.
"""
as_poly(f::Poly) = f
as_poly(T, f::Poly) = convert(Poly{T}, f)

as_poly(xs::Vector{T})  where {T}= Poly(xs)
as_poly(S::T, xs::Vector) where {T} = Poly(convert(Vector{S},xs))

## Try to convert a callable object into a polynomial, `Poly{T}`. `T` can be specified, or guessed from calling `f(0)`.
function as_poly(f)
    T = typeof(f(0))
    as_poly(T, f)
end

"""
as_poly{T}(T, f)

Convert `f` to a polynomial of type `Poly{T}`, or throw a `DomainError`.
"""
function as_poly(T, f)
    p = try
        x = variable(T)
        convert(Poly{T}, f(x))
    catch err
        throw(DomainError)
    end
    p
end


"""

Find coefficients of polynomial expressed as Poly, Callable object, or values [a0,a1, ..., an]

"""
poly_coeffs(ps::Vector{T}) where {T} = ps
poly_coeffs(p::Poly{T}) where {T} = Polynomials.coeffs(p)
poly_coeffs(f) = poly_coeffs(as_poly(f))
poly_coeffs(T, f) = convert(Vector{T}, poly_coeffs(f))

" Type of polynomial "
e_type(p::Poly{T}) where {T} = T
e_type(ps::Vector{T}) where {T} = T
e_type(p) =  eltype(p(0))


"""
reverse coefficients of a polynomial
"""
rcoeffs(p::Poly) = reverse(coeffs(p))

"""
monic
"""
monic(p::Poly) = p[Polynomials.degree(p)] != 0 ? Poly(p.a * inv(p[Polynomials.degree(p)]), p.var) : p


# a robust bisection method
bisection(f, a::Real, b::Real) = Roots.bisection64(f, promote(float(a), b)...)
