"""
    function angle_between(v1, v2)

Calculates the angle between two vectors
"""
function angle_between(v1, v2)
    _v1 = normalize(v1)
    _v2 = normalize(v2)
    angle = acos(min(dot(_v1, _v2), 1))
end


"""
    function azimuth(d::Direction)

Calculate the azimuth angle for a given direction.
"""
azimuth(d) = atan(d[2], d[1])

"""
    function zenith(d::Direction)

Calculate the zenith angle for a given direction.
"""
zenith(d) = acos(-d[3]/norm(d))

"""
    function pld3(p1, p2, d2)

Calculate the distance between a point (p1) and a line (given by p2 and d2).
"""
function pld3(p1, p2, d2)
    norm(cross(d2, (p2 - p1))) / norm(d2)
end


"""
    function lld3(P, u, Q, v)

Calculate the distance between two lines.
"""
function lld3(P, u, Q, v)
    R = Q - P
    n = cross(u, v)
    return norm(R⋅n) / norm(n)
end


"""
    function lld3(t₁::T, t₂::T) where T::Track

Calculate the distance between two tracks.
"""
function lld3(t₁::Track, t₂::Track)
    return lld3(t₁.pos, t₁.dir, t₂.pos, t₂.dir)   
end


"""
    function project(P, t::Track)

Projects a point to a track.
"""
function project(P, t::Track)
    A = t.pos
    B = A + t.dir
    project(P, A, B)
end


"""
    function project(P, A, B)

Project P onto a line spanned by A and B.
"""
function project(P, A, B)
    Position(A + ((P-A)⋅(B-A))/((B-A)⋅(B-A)) * (B-A))
end
