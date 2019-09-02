## Some Polynomial utilities


## conveniences for AbstractAlgebra.jl
# get value of GF(p) in (-p/2, p/2)
function value(x::AbstractAlgebra.gfelem)
    # reach in to get a, q
    q = parent(x).p
    a = x.d
    a <= q ÷ 2 ? a : a - q
end

value(x) = x

function poly_coeffs(f::AbstractAlgebra.Generic.Poly)
#    println("poly coef f=$f d=$(degree(f))")
    d = degree(f)
    d < 0 && return [value(coeff(f, 0))]
    [value(coeff(f, i)) for i in 0:degree(f)]
end

poly_coeffs(as) = as


variable(f::AbstractAlgebra.Generic.Poly) = gen(parent(f))


function maxnorm(f::AbstractAlgebra.Generic.Poly)
    norm(poly_coeffs(f), Inf)
end

function onenorm(f::AbstractAlgebra.Generic.Poly)
    norm(poly_coeffs(f), 1)
end



## Conversion to Generic.Poly
# If f = a0 + a1*y + ... an*y^n then compute
# a0*x + ... an*x^n for x a poly. (Could be different ring, ...)
function as_poly(f::AbstractAlgebra.Generic.Poly, x::AbstractAlgebra.Generic.Poly)
    degree(f) < 0 && return zero(x)
    sum(value(coeff(f, i)) * x^i for i in 0:degree(f))
end


function as_poly(as, x::AbstractAlgebra.Generic.Poly)
    sum( ai * x^(i-1) for  (i,ai) in enumerate(as))
end

# make poly over Z?
function as_poly(f::AbstractAlgebra.Generic.Poly{T}, x::String="x") where {T}
    R,y = ZZ[x]
    sum(value(coeff(f, i)) * y^i for i in 0:degree(f))
end

function as_poly(as, x0::String="x")
    R, x = ZZ[x0]
    as_poly(as, x)
end

# Z[x] with coefficients in (-p/2, p/2)
function _modp(x, p)
    a = mod(x,p)
    a > p ÷ 2 ? a - p : a
end

# make poly over x with coefficients in (-p/2...p/2)
function as_poly_modp(f, p, x::AbstractAlgebra.Generic.Poly)
    as = poly_coeffs(f)
    as_poly(_modp.(as, p), x)
end

# make poly in GP from coefficiens of x
function as_poly_modp(f, p, x0::String="x")
    R, x = GF(p)[x0]
    as = poly_coeffs(f)
    as_poly(_modp.(as, p), x)
end



# Create a polynomial over Zp[x] from the coefficients
# as is (a0,a1, ..., an) as an interable
function as_poly_Zp(f::AbstractAlgebra.Generic.Poly, p, x)
    as_poly_Zp(poly_coeffs(f), p, x)
end
    
function as_poly_Zp(as, p::S, var="x") where {S}
    T = eltype(as)
    R = promote_type(T, S)
    q = convert(R, p)

    F = GF(q)
    R,x = PolynomialRing(F, var)
    sum(ai*x^(i-1) for (i,ai) in enumerate(as))
end
