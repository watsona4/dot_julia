export HCircle, get_center, get_radius, points_on_circle
export RandomHCircle, circumference, area

"""
`HCircle(P::HPoint,r::Real)` creates a new hyperbolic circle
centered at `P` with radius `r`.
"""
struct HCircle <: HObject
    ctr::HPoint
    rad::Float64
    attr::Dict{Symbol,Any}
    function HCircle(P::HPoint,r::Real)
        @assert r>0 "radius must be positive"
        C = new(P,r,Dict{Symbol,Any}())
        set_color(C)
        set_thickness(C)
        set_line_style(C)
        return C
    end
end
HCircle(C::HCircle) = HCircle(C.ctr, C.rad)  # copy constructor

"""
`HCircle(A,B,C)` creates a circle that includes the three given points.
"""
function HCircle(A::HPoint, B::HPoint, C::HPoint)
    @assert !collinear(A,B,C) "The three points must be nonlinear"
    L1 = bisector(A,B)
    L2 = bisector(A,C)
    @assert meet_check(L1,L2) "There is no circle containing these three points"
    P = meet(L1,L2)
    r = dist(A,P)
    return HCircle(P,r)
end

"""
`RandomHCircle()` creates a random circle.
"""
RandomHCircle() = HCircle(RandomHPoint(), -log(rand()) )

"""
`get_center(C::HCircle)` returns the center of the circle.
"""
get_center(C::HCircle) = C.ctr

"""
`get_radius(C::HCircle)` returns the radius of the circle.
"""
get_radius(C::HCircle) = C.rad

function show(io::IO, C::HCircle)
    print(io,"HCircle($(C.ctr),$(C.rad))")
end

"""
`points_on_circle(C::HCircle)` returns a 3-tuple of points
that lie on the circle `C`.
"""
function points_on_circle(C::HCircle)
    P = get_center(C)
    f = inv(move2zero(P))
    r = get_radius(C)
    a = HPoint(r,0)
    b = HPoint(r,2pi/3)
    c = HPoint(r,4pi/3)
    return (f(a), f(b), f(c))
end

HCircle(r::Real = 1) = HCircle(HPoint(), r)

function(==)(C::HCircle, CC::HCircle)
    if abs(C.rad - CC.rad) > THRESHOLD*eps(1.0)
        return false
    end
    return C.ctr == CC.ctr
end 

"""
`circumference(C::HCircle)` returns the circumference of the circle.
"""
function circumference(C::HCircle)
    r = get_radius(C)
    return 2*pi*sinh(r)
end

"""
`area(C::HCircle)` returns the area of the circle.
"""
function area(C::HCircle)
    r = get_radius(C)
    return 4*pi*(sinh(r/2))^2
end


function in(P::HPoint, C::HCircle)::Bool
    d = dist(P, C.ctr)
    return d <= C.rad + THRESHOLD*eps(1.0)   # add a bit of slop
end
