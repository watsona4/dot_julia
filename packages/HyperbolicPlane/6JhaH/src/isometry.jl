export move2zero, move2xplus, rotation, reflect_across, same_side
export in_up, up_in


# This code enables LFT's to act on HObjects.

(f::LFT)(p::HPoint) = HPoint(f(getz(p)))

(f::LFT)(L::HSegment) = HSegment(f(L.A), f(L.B))

(f::LFT)(T::HTriangle) = HTriangle(f(T.A), f(T.B), f(T.C))

function (f::LFT)(L::HLine)
    s = L.s
    t = L.t
    w = exp(s*im)
    z = exp(t*im)
    ww = f(w)
    zz = f(z)
    ss = angle(ww)
    tt = angle(zz)
    return HLine(ss,tt)
end

function (f::LFT)(R::HRay)
    z = exp(im*R.t)
    p = R.pt
    zz = f(z)
    tt = angle(zz)
    pp = f(p)
    return HRay(pp,tt)
end

function (f::LFT)(HC::Horocycle)
    p = HC.pt
    t = HC.t

    pp = f(p)
    z = exp(t*im)
    zz = f(z)
    tt = angle(zz)

    return Horocycle(pp,tt)
end


function (f::LFT)(X::HPolygon)
    pts = f.(X.plist)
    return HPolygon(pts)
end

(f::LFT)(H::HPlane) = HPlane()


# Various LFT creation functions.


"""
`in_up` is a `LFT` that maps the Poincaré disk to the upper half plane.
"""
const in_up = LFT(-im, -im, 1, -1)

"""
`up_in` is a `LFT` that maps the upper half plane to the Poincaré disk.
"""
const up_in = LFT(-1, im, -1, -im)


"""
`move2zero(P::Hpoint)`
returns a `LFT` that's an isometry of H^2 that maps `P` to the origin.
"""
function move2zero(z::Complex)::LFT
    # map to upper half plane and find x-displacement
    zz = in_up(z)
    x = real(zz)

    # move horizontally to place above origin
    f = LFT(1, -x, 0, 1)
    zz = f(zz)

    # move down to 0 + im
    y = imag(zz)
    g =  LFT( 1, -y*im, 1, y*im )

    return g*f*in_up
end

move2zero(P::HPoint) = move2zero(getz(P))

"""
`rotation(theta)` is an isometry of H^2 corresponding to a
rotation about the origin of the amount `theta`
"""
rotation(theta::Real)= LFT( exp(im*theta), 0, 0, 1)


"""
`move2xplus(P::HPoint)` returns an isometry of H^2 that maps `P` onto
the positive real axis.
"""
function move2xplus(z::Complex)::LFT
    if z == 0
        return LFT()
    end
    theta = angle(z)
    return rotation(-theta)
end

move2xplus(P::HPoint) = move2xplus(getz(P))


function move2xplus(a::Complex, b::Complex)
    f = move2zero(a)
    bb = f(b)
    theta = angle(bb)
    g = rotation(-theta)
    return g*f
end

"""
`move2xplus(A,B)` or `move2xplus(L::HSegment)`
gives an isometry `f` so that `f(A)` is 0 and `f(B)` is on the
positive real axis.
"""
move2xplus(A::HPoint, B::HPoint) = move2xplus(getz(A),getz(B))
move2xplus(L::HSegment) = move2xplus(endpoints(L)...)

"""
`move2xplus(L::HLine)` returns a linear fractional transformation
that maps points on `L` to the positive x-axis but is *not* an
isometry of the hyperbolic plane.
"""
function move2xplus(L::HLine)
    a = exp(im*L.s)
    b = getz(point_on_line(L))
    c = exp(im*L.t)
    f = LFT(a,b,c)
    return f
end

function move2xplus(R::HRay)
    A = get_vertex(R)
    w = getz(A)
    z = exp(im * R.t)
    return move2xplus(w,z)
end

"""
`reflect_across(X::HObject,L::HSegment/HLine)` returns the object
formed by refecting `X across the line segment/line `L`.
"""
function reflect_across(p::HPoint, L::Union{HLine,HSegment})
    f = move2xplus(L)
    z = getz(p)
    zz = f(z)'
    w = (inv(f))(zz)
    return HPoint(w)
end

function reflect_across(S::HSegment, L::Union{HLine,HSegment})
    A,B = endpoints(S)
    AA = reflect_across(A,L)
    BB = reflect_across(B,L)
    return HSegment(AA,BB)
end

function reflect_across(T::HTriangle, L::Union{HLine,HSegment})
    A,B,C = endpoints(T)
    AA = reflect_across(A,L)
    BB = reflect_across(B,L)
    CC = reflect_across(C,L)
    return HTriangle(AA,BB,CC)
end

function reflect_across(X::HPolygon, L::Union{HLine,HSegment})
    pts = [ reflect_across(p,L) for p in X.plist ]
    return HPolygon(pts)
end

function reflect_across(X::HLine, L::Union{HLine,HSegment})
    a = exp(im * L.s)
    b = getz(point_on_line(L))
    c = exp(im * L.t)
    f = LFT(a,-1,b,0,c,1)


    Y = f(X)
    s = Y.s
    t = Y.t
    Z = HLine(-s,-t)
    return (inv(f))(Z)
end

reflect_across(X::HPlane, L::Union{HLine,HSegment}) = HPlane()

"""
`same_side(P,Q,L)` determines if the points `P` and `Q`
lie in the same (closed) halfplane as determined by `L`.
If either point is on `L` then the result is `true`.
"""
function same_side(P::HPoint, Q::HPoint, L::HLine)::Bool

    if in(P,L) || in(Q,L)
        return true
    end

    f = move2xplus(L)
    a = imag(f(getz(P)))
    b = imag(f(getz(Q)))


    return sign(a) == sign(b)
end

same_side(P::HPoint, Q::HPoint, S::Union{HSegment,HRay}) = same_side(P,Q,HLine(S))


## UNARY MINUS

"""
`-X` where `X` is a hyperbolic object is a new object reflected through
the origin.
"""
(-)(H::HPlane) = HPlane()
(-)(P::HPoint) = HPoint(-getz(P))
(-)(P::HPolygon) = HPolygon((-).(P.plist))
(-)(C::HCircle) = HCircle( -(C.ctr), C.rad )

function (-)(L::HSegment)
    a,b = endpoints(L)
    return HSegment(-a,-b)
end

function (-)(R::HRay)
    p = -R.pt
    t = R.t + pi
    return HRay(p,t)
end

function (-)(T::HTriangle)
    a,b,c = endpoints(T)
    return HTriangle(-a,-b,-c)
end

function (-)(L::HLine)
    s = L.s
    t = L.t
    return HLine(pi+s,pi+t)
end

function (-)(HC::Horocycle)
    pt = -HC.pt
    t  = HC.t + pi
    return Horocycle(pt,t)
end


## ADJOINT
"""
`adjoint(X::HObject)` (that is, `X'`) returns a new `X` that is reflected
across the `x`-axis.
"""
adjoint(H::HPlane) = HPlane()
adjoint(P::HPoint) = HPoint(getz(P)')
adjoint(P::HPolygon) = HPolygon(adjoint.(P.plist))
adjoint(C::HCircle) = HCircle( (C.ctr)', C.rad )

function adjoint(L::HSegment)
    a,b = endpoints(L)
    return HSegment(a',b')
end

function adjoint(L::HLine)
    s = L.s
    t = L.t
    return HLine(-s,-t)
end

function adjoint(R::HRay)
    p = (R.pt)'
    t = -(R.t)
    return HRay(p,t)
end

function adjoint(HC::Horocycle)
    pt = (HC.pt)'
    t  = -HC.t
    return Horocycle(pt,t)
end

function adjoint(T::HTriangle)
    a,b,c = endpoints(T)
    return HTriangle(a',b',c')
end
