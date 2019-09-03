# This package redefines Complex operations so that there is a single
# complex infinity and a single complex NaN.

import Base.inv, Base.Complex, Base.show, Base.showcompact
import Base.+, Base.-, Base.*, Base./, Base.==

function Complex(x::Real, y::Real)
    if isnan(x) || isnan(y)
        return ComplexNaN
    end

    if isinf(x) || isinf(y)
        return ComplexInf
    end

    if x==0
        x = zero(x)
    end
    if y==0
        y = zero(y)
    end

    return Complex(promote(x,y)...)
end


module RiemannComplexNumbers
"""
Complex not-a-number in the `RiemannComplexNumbers` module.
"""
const ComplexNaN = Complex(NaN,NaN)

"""
Single complex infinity in the `RiemannComplexNumbers` module.
"""
const ComplexInf = Complex(Inf,Inf)

export ComplexNaN, ComplexInf

function my_inv(z::Complex)
    if isnan(z)
        return ComplexNaN
    end
    if isinf(z)
        return zero(z)
    end
    if z == 0
        return ComplexInf
    end
    return my_inv_work(z)
end

my_inv_work(z::Complex)  = conj(z)/abs2(z)
my_inv_work{T<:Integer}(z::Complex{T}) = inv(float(z))


function my_inv_work(w::Complex128)
    c, d = reim(w)
    half = 0.5
    two = 2.0
    cd = max(abs(c), abs(d))
    ov = realmax(c)
    un = realmin(c)
    ep = eps(Float64)
    bs = two/(ep*ep)
    s = 1.0
    cd >= half*ov  && (c=half*c; d=half*d; s=s*half) # scale down c,d
    cd <= un*two/ep && (c=c*bs; d=d*bs; s=s*bs     ) # scale up c,d
    if abs(d)<=abs(c)
        r = d/c
        t = 1.0/(c+d*r)
        p = t
        q = -r * t
    else
        c, d = d, c
        r = d/c
        t = 1.0/(c+d*r)
        p = r * t
        q = -t
    end
    return Complex128(p*s,q*s) # undo scaling
end

# z-->b w-->a
function my_div(a::Complex, b::Complex)
    a,b = promote(a,b)
    if isnan(a) || isnan(b)
        return ComplexNaN
    end
    if isinf(b)
        if isinf(a)
            return ComplexNaN
        end
        return zero(typeof(z=a))
    end
    if b==0
        if a==0
            return ComplexNaN
        end
        return ComplexInf
    end
    return my_div_work(a,b)
end

# Special cases are already handled before this is called. Code taken
# from Julia's complex.jl
function my_div_work(a::Complex, b::Complex)
    are = real(a); aim = imag(a); bre = real(b); bim = imag(b)
    if abs(bre) <= abs(bim)
        r = bre / bim
        den = bim + r*bre
        Complex((are*r + aim)/den, (aim*r - are)/den)
    else
        r = bim / bre
        den = bre + r*bim
        Complex((are + aim*r)/den, (aim - are*r)/den)
    end
end

# Also taken from complex.jl
function my_div_work(z::Complex128, w::Complex128)
    a, b = reim(z); c, d = reim(w)
    half = 0.5
    two = 2.0
    ab = max(abs(a), abs(b))
    cd = max(abs(c), abs(d))
    ov = realmax(a)
    un = realmin(a)
    ep = eps(Float64)
    bs = two/(ep*ep)
    s = 1.0
    ab >= half*ov  && (a=half*a; b=half*b; s=two*s ) # scale down a,b
    cd >= half*ov  && (c=half*c; d=half*d; s=s*half) # scale down c,d
    ab <= un*two/ep && (a=a*bs; b=b*bs; s=s/bs     ) # scale up a,b
    cd <= un*two/ep && (c=c*bs; d=d*bs; s=s*bs     ) # scale up c,d
    abs(d)<=abs(c) ? ((p,q)=robust_cdiv1(a,b,c,d)  ) : ((p,q)=robust_cdiv1(b,a,d,c); q=-q)
    return Complex128(p*s,q*s) # undo scaling
end

end #end of module

show(io::IO, z::Complex)        = print(io, string(z,false))
showcompact(io::IO, z::Complex) = print(io, string(z,true))


#### BASIC FOUR OPERATIONS ####

# Addition

function +(w::Complex, z::Complex)
    w,z = promote(w,z)
    if isnan(w) || isnan(z)
        return ComplexNaN
    end
    if isinf(w)
        if isinf(z)
            return ComplexNaN
        end
        return ComplexInf
    end
    if isinf(z)
        return ComplexInf
    end
    return Complex(w.re+z.re, w.im+z.im)
end

+(w::Complex, x::Real) = w + Complex(x)
+(x::Real, w::Complex) = Complex(x) + w

# Binary minus

function -(w::Complex, z::Complex)
    w,z = promote(w,z)
    if isnan(w) || isnan(z)
        return ComplexNaN
    end
    if isinf(w)
        if isinf(z)
            return ComplexNaN
        end
        return ComplexInf
    end
    if isinf(z)
        return ComplexInf
    end
    return Complex(w.re-z.re, w.im-z.im)
end

-(w::Complex, x::Real) = w - Complex(x)
-(x::Real, w::Complex) = Complex(x) - w

# Unary minus

function -(w::Complex)
    if isnan(w)
        return ComplexNan
    end
    if isinf(w)
        return ComplexInf
    end
    return Complex(-w.re, -w.im)
end

# Multiplication

function *(w::Complex, z::Complex)
    w,z = promote(w,z)
    if isnan(w) || isnan(z)
        return ComplexNaN
    end
    if isinf(w)
        if z==0
            return ComplexNaN
        end
        return ComplexInf
    end
    if isinf(z)
        if w==0
            return ComplexNaN
        end
        return ComplexInf
    end
    return Complex(w.re*z.re - w.im*z.im , w.re*z.im + w.im*z.re)
end

*(w::Complex, x::Real) = w * Complex(x)
*(x::Real, w::Complex) = Complex(x) * w

# Division

/(w::Complex, x::Real) = w * RiemannComplexNumbers.my_inv(Complex(x))
/(x::Real, z::Complex) = Complex(x)*RiemannComplexNumbers.my_inv(z)

/(w::Complex, z::Complex) = RiemannComplexNumbers.my_div(w,z)
/(w::Complex128, z::Complex128) = RiemannComplexNumbers.my_div(w,z)


# These cover the cases in complex.jl (Julia 0.3.10)
inv(w::Complex{Float64}) = RiemannComplexNumbers.my_inv(w)
inv{T<:Integer}(w::Complex{T}) = RiemannComplexNumbers.my_inv(w)
inv{T<:AbstractFloat}(w::Complex{T}) = RiemannComplexNumbers.my_inv(w)
inv(w::Complex) = RiemannComplexNumbers.my_inv(w)

# Equality

function ==(w::Complex, z::Complex)
    if isnan(w) || isnan(z)
        return false
    end
    if isinf(w) && isinf(z)
        return true
    end
    return w.re == z.re && w.im == z.im
end

==(w::Complex, x::Real) = w == Complex(x)
==(x::Real, z::Complex) = Complex(x) == z


import Base.string

function string(z::Complex,compact::Bool=true)
    if isnan(z)
        if compact
            return "C_NaN"
        else
            return "ComplexNaN"
        end
    end

    if isinf(z)
        if compact
            return "C_Inf"
        else
            return "ComplexInf"
        end
    end

    a,b = reim(z)

    # This is to hide -0.0
    if a==0
        a = zero(a)
    end

    if b==0
        b = zero(b)
    end

    sp = " "
    if compact
        sp = ""
    end

    op = "+"
    if b<0
        op = "-"
    end

    return string(a) * sp * op * sp * string(abs(b)) * "im"
end
