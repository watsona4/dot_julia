import SimpleDrawing: newdraw, finish
export newdraw, finish, draw


"""
`draw(X)` draws the hyperbolic object `X` in a graphics window.

`draw` may be applied to a list of hyperbolic objects.

The typical sequence of drawing starts by clearing the screen with the `plot()` function
(from the `Plots` module), then various to calls to `draw` and then
concludes with a call to `finish()` (see the help message for that function).
"""
function SimpleDrawing.draw(P::HPoint)
    x,y = reim(getz(P))
    draw_point(x,y;P.attr...)
end

function SimpleDrawing.draw(S::HSegment)
    P,Q = endpoints(S)

    if P==Q
        return
    end

    M = midpoint(S)

    z = getz(P)
    zz = getz(Q)
    w = getz(M)

    if abs(imag( (z-w)/(zz-w) )) <= THRESHOLD*eps(1.0)   # they're linear
        draw_segment(z,zz;S.attr...)
    else
        draw_arc(z,w,zz; S.attr...)
    end
end

function SimpleDrawing.draw(L::HLine)
    t1 = L.s
    t2 = L.t

    if t1==t2
        return
    end

    x = cos(t1)
    y = sin(t1)
    xx = cos(t2)
    yy = sin(t2)

    if abs(abs(t1-t2)-pi) <= THRESHOLD*eps(1.0)
        draw_segment(x,y,xx,yy;L.attr...)
    else
        P = point_on_line(L)
        m = getz(P)
        draw_arc(x+im*y, m, xx+im*yy; L.attr...)
    end
end


function SimpleDrawing.draw(R::HRay)
    t = R.t
    A = get_vertex(R)
    B = point_on_ray(R)

    a = getz(A)
    b = getz(B)
    c = exp(im*t)

    z = (b-a)/(c-a)  # if this is real, we draw a segment
    if abs(imag(z)) <= THRESHOLD*eps(1.0)
        draw_segment(a,c;R.attr...)
    else
        draw_arc(a,b,c;R.attr...)
    end
end

function SimpleDrawing.draw(HP::HPlane)
    draw_circle(0,0,1; HP.attr...)
end

function SimpleDrawing.draw(list::Array{T,1}) where T <: HObject
    g = plot!()
    for X in list
        g = draw(X)
    end
    return g
end

# SimpleDrawing.draw(args...) = draw(collect(args))

function SimpleDrawing.draw(HO::HObject, args...)
    draw(HO)
    draw(collect(args))
end 


function SimpleDrawing.draw(C::HCircle)
    X,Y,Z= points_on_circle(C)
    draw_circle(getz(X),getz(Y),getz(Z);C.attr...)
end

function SimpleDrawing.draw(HC::Horocycle)
    c = euclidean_center(HC)
    r = abs(getz(HC.pt)-c)
    draw_circle(c,r;HC.attr...)
end


function SimpleDrawing.draw(X::Union{HPolygon,HTriangle})
    for S in sides(X)
        copy_attr(S,X)
        draw(S)
    end
    draw()
end

SimpleDrawing.draw(C::HContainer) = draw(collect(C))
