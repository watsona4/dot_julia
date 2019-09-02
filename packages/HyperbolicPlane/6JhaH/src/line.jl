export HLine, RandomHLine, point_on_line, ∨
export perpendicular, points_on_line

struct HLine <: HObject
    s::Float64
    t::Float64
    attr::Dict{Symbol,Any}
    function HLine(a::Real,b::Real)
        a = mod(a,2pi)
        b = mod(b,2pi)
        @assert a!=b "Invalid line"

        if a>b
            a,b = b,a
        end
        L = new(a,b,Dict{Symbol,Any}())
        set_color(L)
        set_thickness(L)
        set_line_style(L)
        return L
    end
end
HLine(L::HLine) = HLine(H.s,H.t) # copy constructor
HLine() = HLine(0,pi)  #default line is a horizontal diameter

(==)(L::HLine, LL::HLine) = abs(L.s-LL.s)<=THRESHOLD*eps(1.) && abs(L.t-LL.t)<=THRESHOLD*eps(1.)

function show(io::IO, L::HLine)
    s = L.s
    t = L.t
    print(io,"HLine($s,$t)")
end

"""
`HLine(P,Q)` creates a new line from the given two points.
"""
function HLine(P::HPoint, Q::HPoint)
    @assert P != Q "Need two distinct points to determine a line"
    f = move2xplus(P,Q)
    g = inv(f)
    a = angle(g(-1))
    b = angle(g(1))
    return HLine(a,b)
end

(∨)(P::HPoint, Q::HPoint) = HLine(P,Q)

"""
`HLine(S::HSegment)` extends the segment `S` to give a (new) line.
"""
function HLine(S::HSegment)
    P,Q = endpoints(S)
    return HLine(P,Q)
end



"""
`RandomHLine()` returns a random line in the hyperbolic plane.

Algorithm: choose two values `s,t` in `[0,2pi)` uniformly at random
and then make the line from `exp(s*im)` to `exp(t*im)`.
"""
function RandomHLine()::HLine
    x = 2*pi*rand()
    y = 2*pi*rand()
    return HLine(x,y)
end


"""
`point_on_line(L)` returns a point on the hyperbolic line `L`.

See also: `points_on_line`.
"""
function point_on_line(L::HLine)
    PP = points_on_line(L,1)
    return PP[1]
end

"""
`points_on_line(L,n)` returns a list of `n`
distinct points on the line `L`.

See also: `point_on_line`.
"""
function points_on_line(L::HLine,n::Int=2)
    @assert n>0 "$n must be positive"
    s = L.s
    t = L.t
    a = exp(s*im)
    b = exp(t*im)
    ab = exp(im*(s+t)/2)

    # move the three ideal points to -1, 0, 1
    f = LFT(a,-1,ab,0,b,1)
    g = inv(f)

    tlist = [ pi*j/(n+1) for j=1:n ]
    zlist = [ exp(t*im) for t in tlist ]
    Plist = [ HPoint(g(z)) for z in zlist ]
    return Plist
end





# Find the complex point that's the euclidean center of the line as drawn
function e_center(L::HLine)::Complex
    s = L.s
    t = L.t

    if abs((t-s)-pi) <= THRESHOLD*eps(1.0)
        return Inf + Inf*im
    end
    P = point_on_line(L)
    a = exp(im*s)
    b = exp(im*t)
    c = getz(P)
    return find_center(a,b,c)
end

# Fine the euclidean radius
function e_radius(L::HLine)::Real
    s = exp(im*L.s)
    t = exp(im*L.t)
    z = e_center(L)
    if isinf(z)
        return Inf
    end
    r1 = abs(z-s)
    r2 = abs(z-t)
    return (r1+r2)/2
end

function in(P::HPoint, L::HLine)
    PP = reflect_across(P,L)
    return P == PP
end



function issubset(S::HSegment, L::T) where T <: Union{HSegment,HLine}
    P,Q = endpoints(S)
    return in(P,L) && in(Q,L)
end

"""
`perpendicular(L::HLine, P::HPoint)` returns a line that is
perpendicular to `L` and contains `P`.
"""
function perpendicular(L::HLine, P::HPoint)::HLine
    if in(P,L)   # case when the point is on L
        f = move2zero(P)
        g = inv(f)
        LL = f(L)
        s = LL.s + pi/2
        t = LL.t + pi/2
        return g(HLine(s,t))
    end
    # case when P is not on L
    PP = reflect_across(P,L)
    return HLine(P,PP)
end

"""
`perpendicular(L)` returns an arbitrary line that is perpendicular to `L`.
"""
perpendicular(L::HLine)::HLine = perpendicular(L, point_on_line(L))
perpendicular(P::HPoint, L::HLine) = perpendicular(L,P)

"""
`dist(P::HPoint,L::HLine)` is the distance from `P`
to the nearest point on `L`.
"""
function dist(P::HPoint,L::HLine)
    LP = perpendicular(L,P)
    Q = meet(LP,L)
    return dist(P,Q)
end

dist(L::HLine, P::HPoint) = dist(P,L)
