
export Horocycle, RandomHorocycle

"""
`Horocycle(P::HPoint, theta::Real)` create the horocycle
containing the point `P` and the ideal point at `exp(im*theta)`.
"""
struct Horocycle <: HObject
    pt::HPoint
    t::Float64
    attr::Dict{Symbol,Any}
    function Horocycle(P::HPoint, theta::Real)
        theta = mod(theta,2pi)
        f = rotation(-theta)
        g = rotation(theta)
        # pt = P # put something

        z = f(getz(P))  # map to +x axis
        x,y = reim(z)

        a = (x^2 + y^2 - x)/(x - 1)
        w = a + 0im
        PP = g(HPoint(w))


        HC = new(PP,theta,Dict{Symbol,Any}())
        set_color(HC)
        set_thickness(HC)
        set_line_style(HC)
        return HC
    end
end
Horocycle() = Horocycle(HPoint(), 0)

Horocycle(t::Real,p::HPoint) = Horocycle(p,t)

# Copy constructor
Horocycle(HC::Horocycle) = Horocycle(HC.pt, HC.t)

"""
`RandomHorocycle()` creates a random horocycle by choosing
a point at random by `RandomHPoint` and a random ideal
point (uniformly between 0 and 2π).
"""
RandomHorocycle() = Horocycle(RandomHPoint(), 2*pi*rand())

function show(io::IO, HC::Horocycle)
    print(io,"Horocycle($(HC.pt),$(HC.t))")
end

function euclidean_center(HC::Horocycle)::Complex
    z = getz(HC.pt)
    w = exp(im*HC.t)
    return (z+w)/2
end

function(==)(H1::Horocycle, H2::Horocycle)
    if abs(H1.t-H2.t) > THRESHOLD * eps(1.0)
        return false
    end
    return H1.pt == H2.pt
end
