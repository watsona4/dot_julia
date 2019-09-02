export HRay, RandomHRay, get_vertex, point_on_ray

"""
`HRay(P::HPoint, t::Real)` returns a ray with vertex `P`
pointing to `exp(im*t)`.
"""
struct HRay <: HObject
    pt::HPoint
    t::Float64
    attr::Dict{Symbol,Any}
    function HRay(P::HPoint, theta::Real)
        th = mod(theta,2pi)
        PP = HPoint(getz(P))
        R = new(PP,th,Dict{Symbol,Any}())
        set_color(R)
        set_thickness(R)
        set_line_style(R)
        return R
    end
end
HRay(R::HRay) = HRay(R.pt, R.t)  # copy constructor
HRay() = HRay(HPoint(),0.0)

"""
`HRay(A,B)` where `A` and `B` are points creates the ray
with vertex `A` passing through `B`.
"""
function HRay(A::HPoint, B::HPoint)
    @assert A!=B "Points must be distinct to define a ray"
    f = move2xplus(A,B)
    g = inv(f)
    z = g(1)
    t = angle(z)
    return HRay(A,t)
end


"""
`RandomHRay()` creates a random ray. `RandomRay(P::HPoint)` creates a
random ray with vertex `P`.
"""
RandomHRay(P::HPoint) = HRay(P, 2*pi*rand())
RandomHRay() = RandomHRay( RandomHPoint() )

"""
`get_vertex(R::HRay)` returns the vertex (end point) of the ray.
"""
get_vertex(R::HRay) = R.pt

function (==)(R::HRay, RR::HRay)
    R.pt == RR.pt && abs(exp(im*R.t) - exp(im*RR.t)) <= THRESHOLD * eps(1.0)
end

function show(io::IO, R::HRay)
    P = R.pt
    t = R.t
    print(io,"HRay($P,$t)")
end


function HLine(R::HRay)
    f = move2xplus(R)
    g = inv(f)
    a = g(-1)
    b = g(1)
    s = angle(a)
    t = angle(b)
    return HLine(s,t)
end

"""
`point_on_ray(R::HRay)` returns a point in the interior of the ray.
"""
function point_on_ray(R::HRay)
    f = move2xplus(R)
    g = inv(f)
    P = g(HPoint(1,0))
    return P
end

"""
`in(P::HPoint, R::HRay)` determine if `P` lies on the ray `R`.
"""
function in(P::HPoint, R::HRay)
    f = move2xplus(R)
    z = f(getz(P))
    return abs(imag(z)) <= THRESHOLD*eps(1.0) && real(z) >= -THRESHOLD*eps(1.0)
end

## TO DO LIST

# meet of rays with each other, lines, segments
# reflect_across
