module SimpleDrawing
using Plots, LinearAlgebra

export newdraw, draw_circle, draw_arc, draw_segment, draw_point, draw_vector
export find_center, non_colinear_check
export finish, draw

"""
`newdraw()` clears the screen and sets up a blank drawing canvas with
no axis, grid, or legend, and sets the aspect ratio to 1.
"""
function newdraw()
    plot(aspectratio=1, legend=false, axis=false, grid=false)
end

function draw()
end

"""
`draw_circle(x,y,r)` (or `draw_circle(z,r)`) draws a circle centered
at `(x,y)` (at `z`) with radius `r`.
"""
function draw_circle(x::Real, y::Real, r::Real; opts...)
    f(t) = r*cos(t) + x
    g(t) = r*sin(t) + y
    plot!(f,g,0,2pi;opts...)
end

draw_circle(z::Complex, r::Real; opts...) =
    draw_circle(real(z), imag(z), r; opts...)

"""
`draw_circle(a,b,c)` draws a circle through the points given by
the three complex arguments.
"""
function draw_circle(a::Complex, b::Complex, c::Complex; opts...)
    z = find_center(a,b,c)
    r = abs(a-z)
    x,y = reim(z)
    draw_circle(x,y,r; opts...)
end


"""
`draw_arc(x,y,r,t1,t2)` draws the shorter arc centered at `(x,y)`
with radius `r` between angles `t1` and `t2`.
"""
function draw_arc(x::Real, y::Real, r::Real, t1::Real, t2::Real; opts...)
    f(t) = r*cos(t) + x
    g(t) = r*sin(t) + y

    plot!(f,g,t1,t2;opts...)
end



"""
`draw_arc(a,b,c)` where the arguments are `Complex`: Draw the
arc from `a` through `b` to `c`.
"""
function draw_arc(a::Complex, b::Complex, c::Complex; opts...)
    m2pi(x::Real) = mod(x,2π)

    z = find_center(a,b,c)
    x,y = reim(z)
    r = abs(b-z)
    ta = m2pi(angle(a-z))
    tb = m2pi(angle(b-z))
    tc = m2pi(angle(c-z))

    if ta > tc
        ta,tc = tc,ta
    end


    if ta<tb<tc
        return draw_arc(x,y,r,ta,tc; opts...)
    end


    return draw_arc(x,y,r,tc-2pi,ta; opts...)
end



"""
`draw_segment(x,y,xx,yy)` draws a line segment from `(x,y)` to
`(xx,yy)`. Also `draw_segment(z,zz)` for `Complex` arguments.
"""
function draw_segment(a::Real,b::Real,c::Real,d::Real; opts...)
    plot!([a,c],[b,d];opts...)
end

function draw_segment(a::Complex, b::Complex; opts...)
    x,y = reim(a)
    xx,yy = reim(b)
    draw_segment(x,y,xx,yy; opts...)
end


"""
`draw_point(x,y)` [or `draw_point(z)`] draws a point at coordinates `(x,y)`
[or complex location `z`].

`draw_point(list)` plots all the points in the one-dimensional `list` of
complex values.
"""
function draw_point(x::Real, y::Real; opts...)
    plot!([x],[y];marker=1,opts...)
end

draw_point(z::Complex; opts...) = draw_point(real(z),imag(z); opts...)

function draw_point(pts::Array{Complex{T},1};opts...) where T
    for p in pts
        draw_point(p;opts...)
    end
end

"""
`draw_vector` is used to draw vectors (line segments with an arrow at one end).
The variations are:
+ `draw_vector(x,y)` draws a vector from the origin to `(x,y)`.
+ `draw_vector(x,y,basex,basey)` draws a vector from `(basex,basey)` to
`(basex+x,basey+y)`.
+ `draw_vector(z)` draws a vector from the origin to the complex value `z`.
+ `draw_vector(z,basez)` draws a vector from the complex location `basez` to
`z+basez`.
"""
draw_vector(x::Real,y::Real; opts...) = draw_segment(0,0,x,y;arrow=:arrow, opts...)

draw_vector(z::Complex;opts...) = draw_segment(0+0im, z; arrow=:arrow, opts...)

draw_vector(x::Real,y::Real,basex::Real,basey::Real; opts...) =
    draw_segment(basex,basey,basex+x,basey+y; arrow=:arrow, opts...)

draw_vector(z::Complex, basez::Complex; opts...) =
    draw_segment(basez, basez+z; arrow=:arrow, opts...)


"""
`finish()` is used to clean up a drawing after various calls to `draw`.
It removes the axes and the grid lines, and sets the aspect ratio to one.
"""
function finish()
    plot!(aspectratio=1, legend=false, axis=false, grid=false)
end



export find_center, non_colinear_check

"""
`find_center(a,b,c)`: Given three points in the complex plane,
find the point `z` that is equidistant from all three. If the three
points are collinear then return `Inf + Inf*im`.
"""
function find_center(a::Complex, b::Complex, c::Complex)::Complex
    if !non_colinear_check(a,b,c)
        return Inf + im*Inf
    end
    A = collect(reim(a))
    B = collect(reim(b))
    C = collect(reim(c))
    AB = 0.5*(A+B)
    BC = 0.5*(B+C)
    M = [(A-B)'; (B-C)']
    rhs = [dot(AB,A-B), dot(BC,B-C)]

    Z = M\rhs
    return Z[1] + im*Z[2]
end

"""
`non_colinear_check(a,b,c)`: test if the complex numbers are distinct
and noncollinear.
"""
function non_colinear_check(a::Complex,b::Complex, c::Complex)::Bool
    if a==b || b==c || a==c
        return false
    end
    z = (b-a)/(c-a)
    return imag(z) != 0
end

include("cubic.jl")
include("curve.jl")


end
