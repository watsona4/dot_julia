module PolynomialZeros



using Polynomials
import PolynomialRoots

using PolynomialFactors
import Roots: bisection64


using AbstractAlgebra
const AA = AbstractAlgebra

using Printf


export poly_roots
export Over

# export agcd, multroot # qualify these





include("utils.jl")
include("over.jl")
include("special_cases.jl")

include("agcd/agcd.jl")        # AGCD.agcd
include("agcd/multroot.jl")    # MultRoot.multroot
include("amvw/AMVW.jl")        # AMVW.poly_roots
include("RealRoots/real_roots.jl")  # RealRoots.real_roots(p::Poly)


using .AGCD
using .MultRoot





"""

`poly_roots(f, domain)`: Find zeros of the polynomial `f` within the specified domain.

* `f` can be an instance of `Poly` type (from `Polynomials.jl`) or a callable object which can be so converted. Will throw a `DomainError` if the object `f` can not be converted to `Poly{T}`.

* `domain` is one of

    - `over.C` (the default) for solving over complex values
      (`Complex{Float64}`). Use `Over.CC{T}` to specfy a type `T<:
      AbstractFloat` other than `Float64`. The default method is from
      `PolynomialRoots`. Pass the argument `method=:roots` to use the
      `roots` function from `Polynomials.jl`. Pass the argument
      `method=:amvw` to use an algorithm by Aurentz, Mach, Vandebril,
      and Watkins. For a degree n polynomial over C, all n roots
      should be returned (including multiplicities).

    - `over.R` for solving over the real line (`Float64`). Use
      `Over.RR{T}` to specify a `T <: Integer` other than
      `Float64`. The algorithm assumes the polynomial is square free
      (none of its factors are squares over R). This is important for
      floating point coefficients. Pass the argument
      `square_free=false` to have an *approximate* gcd used to create
      a square-free version. Only unique real roots are returned (no
      multiplicities).

    - `over.Q` for solving over the rational numbers
      (`Rational{Int}`). Use `Over.RR{T}` to specify a `T <: Integer`
      other than `Int`. Only unique rational roots are returned (no
      multiplicities).

    - `over.Z` for solving over the integers (`Int`). Use `Over.ZZ{T}`
      to specify a `T` other than `Int`. Only unique integer roots are
      returned (no multiplicities).

    - `over.Zp{p}` for solving over the finite field `ZZ_p`, p a
      prime.  Only unique roots are returned (no multiplicities).

Returns an array of zeros, possibly empty. May throw error if polynomial type is inappropriate for specified domain. For an unspecified domain, the domain may reflect the element type of `f(0)`.

Examples:

```julia
using Polynomials, PolynomialZeros
x = variable(); p = x^5 - x - 1
poly_roots(p, Over.C)  # 5
poly_roots(p, Over.R)  # 1
poly_roots(p, Over.Q)  # empty

p = x^3 - 1
poly_roots(p, Over.C)  # 3
poly_roots(p, Over.R)  # 1
poly_roots(p, Over.Q)  # 1
poly_roots(p, Over.Z)  # 1
poly_roots(p, Over.Zp{7})  # 3
```

"""
function poly_roots(f; method=:PolynomialRoots)
    poly_roots(f, Over.C; method=method) # default
end

function poly_roots(f, ::Type{Over.C}; method=:PolynomialRoots)
    T = promote_type(Float64, e_type(f))
    poly_roots(f, Over.CC{T}, method=method)
end

function poly_roots(f, U::Type{Over.CC{T}}; method=:PolynomialRoots) where {T<:AbstractFloat}


    ps = poly_coeffs(T, f)
    fn = special_case(ps, U)

    if fn == identity
        if method == :PolynomialRoots && T <: Union{Float64, BigFloat}
            PolynomialRoots.roots(ps, polish=true)
        elseif method == :Roots && T <: Float64
            convert(Vector{Complex{T}}, Polynomials.roots(Poly(ps)))
        elseif (method == :AMVW || method == :amvw)
            AMVW.poly_roots(ps)
        else # default to AMVW
            AMVW.poly_roots(ps)
        end
    else
        fn(ps, U)
    end

end



function poly_roots(f, ::Type{Over.R};square_free=false)
    T = promote_type(Float64, e_type(f))
    poly_roots(f, Over.RR{T}, square_free=square_free)
end
function poly_roots(f, U::Type{Over.RR{T}}; square_free::Bool=false) where {T <: Real}

    ps = convert(Vector{T}, poly_coeffs(f))
    fn = special_case(ps, U)

    if fn == identity
        RealRoots.real_roots(as_poly(T, f), square_free=square_free)
    else
        fn(ps, U)
    end

end
# should I do an alias? Best to add if requestd, keeping name space light for now
## realroots(f; kwargs...) = poly_roots(f, Over.R; kwargs...) #real_roots?

_rational_T(::Type{Rational{T}}) where {T}= T
_rational_T(::Rational{T}) where {T} =T
function poly_roots(f, ::Type{Over.Q})
    T = promote_type(Int, e_type(f))

    if T <: Integer
        return poly_roots(f, Over.QQ{T})
    elseif T <: Rational
        S = promote_type(_rational_T(T), Int)
        p = as_poly(T, f)
        return poly_roots(f, Over.QQ{S})
    else
        throw(ArgumentError("Use Over.Q for polynomials with integer or rational coefficients"))
    end
end

# for v0.6 -> v0.7 transition on filter with Dicts

function poly_roots(f, U::Type{Over.QQ{T}}) where {T <: Integer}
    p = as_poly(Rational{T}, f)
    fn = special_case(poly_coeffs(p), U)
    if fn == identity
        ps = poly_coeffs(p)
        l = lcm(denominator.(ps))
        qs = numerator.(l * ps)
        d = PolynomialFactors.poly_factor(qs)
        d = filter(kv -> AA.degree(kv[1]) == 1, d) ## is this broken
        rts = Rational{T}[]
        for k in keys(d)
            p0 = k(0); p1 = k(1) - p0
            push!(rts, -p0//p1)
        end
        rts
    else
        fn(p.a, U)
    end

end

## ----

function poly_roots(f, ::Type{Over.Z})
    T = eltype(as_poly(f)(0))
    poly_roots(f, Over.ZZ{T})
end

function poly_roots(f, U::Type{Over.ZZ{T}}) where {T <: Integer}

    p = as_poly(T, f)

    fn = special_case(poly_coeffs(p), U)
    if fn == identity
        d = PolynomialFactors.poly_factor(poly_coeffs(p))
        d = filter(kv -> AA.degree(kv[1]) == 1, d)
        rts = T[]
        for (k,v) in d
            x1, x0= k(1)-k(0), k(0)
            if iszero(rem(x0, x1))
                push!(rts, div(x0, x1))
            end
        end
        rts
    else
        fn(p.a, U)
    end
end



function poly_roots(f, U::Type{Over.Zp{q}}) where {q}
    # error if q is not prime?

    p = as_poly(e_type(f), f)
    paa = PolynomialFactors.as_poly(p.a)

    fn = special_case(poly_coeffs(p), U)
    if fn == identity
        fs = PolynomialFactors.factormod(paa,q)
        ls = filter(kv -> AA.degree(kv[1]) == 1, fs)
        rts = eltype(p.a)[]
        for (k,v) in ls
            x0 = k(0)
            x1 = k(1) - k(0)
            u = x0 * inv(x1)
            push!(rts, PolynomialFactors.value(u))
        end
        rts
    else
        fn(p.a, U)
    end

end



end # module
