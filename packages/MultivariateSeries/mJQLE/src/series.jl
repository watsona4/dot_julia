###
### Series as dictionary between monomials and values, representing
### linear functionals on polynomials.
###
### Bernard Mourrain
###


export Series, series, zero, convert, monomials, setindex, setindex!, deg, integrate, +, -, *, /, scale, scale!

import Base:
    show, print, length, getindex, setindex!, copy, promote_rule, convert, eltype, iterate,
    *, /, //, -, +, ==, ^, divrem, conj, rem, real, imag, diff

import LinearAlgebra: dot,  norm #,  scale!
#----------------------------------------------------------------------
"""
```
Series{C,M}
```
Class representing multivariate series. The series is a dictionary,
which associates values of type C to monomials of type M.
"""
mutable struct Series{C,M}
    terms::Dict{M,C}

    function Series{C,M}() where {M, C}
        new(Dict{M,C}())
    end

    function Series{C,M}(c::C, m::M) where {C, M}
        new(Dict(m => c))
    end
    function Series{C,M}(t::Dict{M,C}) where {C,M}
        new(t)
    end
end
#----------------------------------------------------------------------

function series(c::C, m::M) where {C <: Number, M <: AbstractMonomial}
    Series{C,M}(Dict(m => c))
end

MultivariatePolynomials.terms(p::Series) = p.terms
MultivariatePolynomials.monomials(p::Series) = keys(p.terms)

Base.eltype(::Series{C,M}) where {M, C} = C

Base.zero(::Type{Series{C,M}}) where {M, C} = Series{C,M}()
Base.zero(p::Series{C,M}) where {M, C} = zero(Series{C,M})

Base.one(::Type{Series{C,M}}) where {M, C} = Series{C,M}(Dict(zeros(Int, length(vars)) => one(C)), vars)
Base.one(p::Series{C,M}) where {M, C} = one(Series{C,M}, vars=variables(p))

Base.promote_rule(::Type{Series{C,M}}, ::Type{Series{U,M}}) where {C,M,U} = Series{promote_type(C, U),M}
Base.promote_rule(::Type{Series{C,M}}, ::Type{U}) where {C,M,U} = Series{promote_type(C, U),M}

function convert(P::Type{Series{C,M}}, p::Series) where {M, C}
    r = zero(P)
    for (m, c) in p
        r[m] = convert(C, c)
    end
    r
end

Base.convert(::Type{Series{C,M}}, c::C) where {C, M} =
    Series{C,M}(Dict(M() => c))

Base.getindex(p::Series{C,M}, m::M) where {C, M} =
    get(p.terms, m, zero(C))

Base.getindex(p::Series, m::Int...) = p[[m...;]]

function setindex!(p::Series{C,M}, v, m::M) where {C, M}
    if isapprox(v, zero(C)) #method_exists(isapprox, (C,C)) &&
        delete!(p.terms, m)
    else
        p.terms[m] = v
    end
end

#start(p::Series) = start(p.terms)
#next(p::Series, state) = next(p.terms, state)
#done(p::Series, state) = done(p.terms, state)
Base.iterate(p::Series) = Base.iterate(p.terms)
Base.iterate(p::Series, state) = Base.iterate(p.terms, state)

#----------------------------------------------------------------------
copy(p::Series{C,M}) where {C, M} = Series{C,M}(copy(p.terms))
#----------------------------------------------------------------------
function MultivariatePolynomials.variables(s::Series)
    for (m, c) in s
        return variables(m)
    end
end

#----------------------------------------------------------------------
function norm(s::Series{C,M}, x::Float64) where {C,M}
    if (x == Inf)
        r = - Inf
        for (m, c) in s
            r = max(r, abs(c))
        end
    else
        r = Inf
        for (m, c) in s
            r = min(r, abs(c))
        end
    end
    r
end

function norm(s::Series{C,M}, p::Int64=2) where {C,M}
    r = zero(C)
    for (m, c) in s
        r += abs(c)^p
    end
    r^(1/p)
end

#----------------------------------------------------------------------
function +(s1::Series{C,M}, s2::Series{C,M}) where {C,M}
    r = s1;
    for (m, c) in s2
        v = r[m] + c
        if v == zero(C)
            delete!(terms(r), m)
        else
            terms(r)[m] = v
        end
    end
    r
end

function +(s::Series{C,M}...) where {C,M}
    r = zero(Series{C,M})
    for i = 1:length(s)
        for (m, c) in s[i]
            r[m] += c
        end
    end
    r
end

function +(p::Series{C,M}, s::U) where {C,M,U}
    r = copy(convert(Series{promote_type(C,U),M}, p))
    r[1] += s
    r
end

+(s, p::Series) = p + s

#----------------------------------------------------------------------
function -(s1::Series{C,M}, s2::Series{U,M}) where {C,M,U}
    R = promote_type(C, U)
    r = convert(Series{R,M}, s1)
    for (m, c) in s2
        v = r[m] - c
        if v == zero(R)
            delete!(terms(r), m)
        else
            terms(r)[m] = v
        end
    end
    r
end

function -(s::Series{C,M}, u::U) where {C,M,U}
    r = copy(convert(Series{promote_type(C, U), M}, s))
    r[zeros(Int, nvariables(s))] -= u
    r
end

function -(s::Series)
    r = zero(p)
    for (m, c) in s
        r[m] = -c
    end
    r
end

-(s, p::Series) = -p + s


function *(s1::Series, s2::Series)
    r = zero(s1)
    for (m1, c1) in s1
        for (m2, c2) in s2
            r[m1*m2] += c1 * c2
        end
    end
    r
end

function *(u::U, s::Series{C,M}) where {U <: Number, C,M}
    r = zero(Series{promote_type(C,U),M})
    for (m, c) in s
        r[m] = u * c
    end
    r
end

function *(s::Series{C,M}, u::U) where {U <: Number, C,M}
    r = zero(Series{promote_type(C,U),M})
    for (m, c) in s
        r[m] = c * u
    end
    r
end


function /(p::Series{C,M}, s::U) where {C,M, U <: Number}
    r = zero(Series{promote_type(C,U),M})
    for (m, c) in p
        r[m] = c/s
    end
    r
end

function ^(s::Series, power::Integer)
    @assert power >= 0
    if power == 0
        return one(s)
    elseif power == 1
        return s
    else
        f, r = divrem(power, 2)
        return s^(f+r) * s^f
    end
end

"""
Multiply the elements of L by the variable v
"""
function *(L::AbstractVector, v::AbstractVariable)
    [p*v for p in L]
end
#----------------------------------------------------------------------
"""
```
maxdegree(σ::Series) -> Int64
```
Maximal degree of the moments defined in the series `σ`.
"""
function maxdegree(s::Series)
    d = 0
    for (m, c) in s
        s = degree(m)
        if s > d
            d = s
        end
    end
    d
end

#----------------------------------------------------------------------
"""
```
 inv(m :: Monomial)
```
 return the inverse monomial with opposite exponents.
"""
function Base.inv(m:: M) where M <: AbstractMonomial
    M(variables(m),-exponents(m))
end

function Base.inv(v:: V) where V <: AbstractVariable
    M = monomialtype(V)
    inv(M(v))
end

function isprimal(m::M) where M <: AbstractMonomial
    return !any(t->t<0, exponents(m))
end

#----------------------------------------------------------------------
"""
```
 *(v::Variable,   σ::Series{C,M}) -> Series{C,M}
 *(m::Monomial,   σ::Series{C,M}) -> Series{C,M}
 *(t::Term,       σ::Series{C,M}) -> Series{C,M}
 *(p::Polynomial, σ::Series{C,M}) -> Series{C,M}
```
The dual product (or co-product) where variables are inverted in the polynomial and the monomials with positive exponents are kept in the series.
"""
function *(v::V, s::Series{C,M}) where {V <: AbstractVariable, C,M}
    r = Series{C,M}()
    for (m,c) in s
        n = m*inv(v)
        if isprimal(n)
            r[n]= c
        end
    end
    return r
end

function *(m0::M, s::Series{C,M}) where {C,M <: AbstractMonomial}
    r = Series{C,M}()
    for (m,c) in s
        n = m*inv(m0)
        if isprimal(n)
            r[n]= c
        end
    end
    return r
end

function *(t::T, s::Series{C,M}) where {C,M <: AbstractMonomial,
                                        T<:AbstractTerm}
    return coefficient(t)*(monomial(t)*s)
end

function *(p::P, s::Series{C,M}) where {C, M <:AbstractMonomial,
                                        P<:AbstractPolynomial}
    r = Series{C,M}()
    for t in terms(p)
        r = r + t*s
    end
    return r
end

function Base.truncate(s::Series{C,M}, d::Int64) where {C,M}
    r = Series{C,M}()
    for (m,c) in s
        if degree(m)<= d
            r[m]= c
        end
    end
    return r
end
#----------------------------------------------------------------------
function ==(p::Series, q::Series)
    for (m, c) in p
        if !isapprox(q[m], c)
            return false
        end
    end
    for (m, c) in q
        if !isapprox(p[m], c)
            return false
        end
    end
    true
end

#----------------------------------------------------------------------
"""
Scale the moments ``σ_α`` by ``λ^{deg(α)}``.
"""
function scale(sigma::Series, lambda)
    r = zero(sigma)
    for (m, c) in sigma
        r[m] = c*lambda^deg(m)
    end
    return r
end

#----------------------------------------------------------------------
"""
Scale the moments ``σ_α`` by ``λ^{deg(α)}``, overwriting ``σ``
"""
function scale!(s::Series, lambda)
    for (m, c) in s
        s[m] *= lambda^deg(m)
    end
    return s
end

#----------------------------------------------------------------------
function integrate(s::Series{C,M}, v::V) where {C,M, V<: AbstractVariable}
    r = Series{C,M}()
    for (m,c) in s
        n = m*v
        r[n]= c
    end
    return r
end

#----------------------------------------------------------------------
"""
```
dot(σ::Series{C,M}, p::Monomial) -> C
dot(σ::Series{C,M}, p::Term) -> C
dot(σ::Series{C,M}, p::Polynomial) -> C
dot(σ::Series{C,M}, p::Polynomial, q::Polynomial) -> C
```
Compute the dot product ``‹ p, q ›_{σ} = ‹ σ | p q ›`` or  ``‹ σ | p ›`` for p, q polynomials, terms or monomials.
Apply the linear functional `sigma` on monomials, terms, polynomials 
""" 
function LinearAlgebra.dot(sigma::Series{C,M}, m::M) where {C,M<:AbstractMonomial}
    return sigma[m]
end

function LinearAlgebra.dot(sigma::Series{C,M}, t::T) where {C,M, T<:AbstractTerm}
    return coefficient(t)*sigma[monomial(t)]
end

function LinearAlgebra.dot(sigma::Series{C,M}, p::P) where {C,M, P<:AbstractPolynomial}
    r = zero(C)
    for t in p
        r+= coefficient(t)*sigma[monomial(t)]
    end
    return r
end

function LinearAlgebra.dot(sigma::Series{C,M}, p::P, q::P) where {C,M, P}
    dot(sigma, p*q)
end


#----------------------------------------------------------------------
function show(io::IO, p::Series)
    print(io, p)
end

#----------------------------------------------------------------------
function printmonomial(io::IO, m::M) where M
    if !isconstant(m)
        needsep = false
        for i in 1:length(m.z)
            if m.z[i] != 0
                if needsep
                    print(io, '*')
                end
                print(io,'d')
                show(io, m.vars[i])
                if m.z[i] > 1
                    print(io, '^')
                    print(io, m.z[i])
                elseif m.z[i] < 0
                    print(io, "^(")
                    print(io, m.z[i])
                    print(io, ")")
                else
                    needsep = true
                end
            end
        end
    end
end

#----------------------------------------------------------------------
function print(io::IO, p::Series{C,M}) where {M, C}
    first = true
    for (m, c) in p
        if first
            if C <: Complex
                if degree(m) == 0
                    print(io, "$c")
                else
                    print(io, "($c)*")
                end
            else
                if degree(m) == 0 || c != one(C)
                    print(io, c)
                end
            end
            printmonomial(io, m)
            first = false
        else
            if C <: Complex
                if degree(m) == 0
                    print(io, " + $c")
                else
                    print(io, " + ($c)*")
                end
            else
                if c >= zero(C)
                    if degree(m) != 0 && c == one(C)
                        print(io, " + ")
                    else
                        print(io, " + $c")
                    end
                else
                    print(io, " - $(-c)")
                end
            end
            printmonomial(io, m)
        end
    end
    if first
        print(io, zero(C))
    end
end
