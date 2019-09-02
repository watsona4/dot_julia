export HPoint, getz, dist, midpoint, RandomHPoint, between, polar



"""
`HPoint(z::Complex)` creates a new point in the hyperbolic plane.
The argument `z` must have absolute value less than 1.

`HPoint(r,theta)` creates a new point with polar coordinates
`(r,theta)`. See also: `polar`.
"""
struct HPoint <: HObject
    z::Complex{Float64}
    attr::Dict{Symbol,Any}
    function HPoint(z::Complex)
        if _mag(z) >=  1
            throw(DomainError(z, "absolute value is too large"))
        end
        P = new(z,Dict{Symbol,Any}())
        set_color(P)
        set_radius(P)
        return P
    end
end

HPoint(P::HPoint) = HPoint(getz(P))  # copy constructor
HPoint(z::Number) = HPoint(Complex(z))
HPoint() = HPoint(0)

function show(io::IO,P::HPoint)
    r,theta = polar(P)
    print(io,"HPoint($r, $theta)")
end

"""
`RandomHPoint()` generates a point at random in the hyperbolic plane.
"""
RandomHPoint() = HPoint(randn(), 2*pi*rand())


"""
`getz(P::HPoint)` returns the point (complex number) in the
interior of the unit disc that represents `P`.
"""
getz(P::HPoint) = P.z

"""
`dist(P,Q)` gives the distance betwen two points in the
hyperbolic plane. If `Q` is omitted, give the distance
from `P` to `HPoint(0)`.
"""
function dist(P::HPoint, Q::HPoint)
    a = getz(P)
    b = getz(Q)
    delta = 2 * _mag(a-b)/(1-_mag(a))/(1-_mag(b))
    return acosh(1+delta)
end


dist(P::HPoint) = dist(P, HPoint(0))


HPoint(r::Real, theta::Real) = HPoint( solve_dist(r) * exp(im*theta) )




"""
`polar(P::HPoint)` gives the polar coordinates of `P`
"""
function polar(P::HPoint)
    r = dist(P)
    theta = angle(getz(P))
    return (r,theta)
end

(==)(P::HPoint,Q::HPoint) = _mag(getz(P)-getz(Q)) <= THRESHOLD*eps(1.0)

function _dist(t::Real)
    delta = 2*t*t/(1-t*t)
    return acosh(1+delta)
end

"""
`solve_dist(d)` is the inverse of `_dist()`
"""
function solve_dist(d::Real)
    ex = exp(d)
    return (ex-1)/(ex+1)
end



"""
`midpoint(p,q)` finds the mid point of the line segment
from `p` to `q`. Also `midpoint(L::HSegment)`.
"""
function midpoint(p::HPoint, q::HPoint)::HPoint
    if p==q
        return p
    end
    d = dist(p,q)
    f = move2xplus(p,q)

    t = solve_dist(d/2)

    r = HPoint(t)
    h = inv(f)
    return h(r)
end

"""
`between(a,b,c)` determines if the hyperbolic point `b`
lies on the segment from `a` to `c`.
"""
function between(a::HPoint, b::HPoint, c::HPoint)::Bool
    if a==b || b==c
        return true
    end
    f = move2xplus(a,c)
    aa = getz(f(a))
    bb = getz(f(b))
    cc = getz(f(c))

    if abs(imag(bb)) > THRESHOLD * eps(1.0)
        return false
    end

    if real(aa)-THRESHOLD*eps(1.0) <= real(bb) <= real(cc)+THRESHOLD*eps(1.0)
        return true
    end
    return false
end
