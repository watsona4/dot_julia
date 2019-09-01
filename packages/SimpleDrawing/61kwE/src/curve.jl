export draw_curve

"""
`draw_curve(plist)` draws a closed curve through points in the
`plist` which is a 1-dimensional list of complex numbers.
Use `draw_curve(plist,false)` for an open curve.
"""
function draw_curve(pts::Array{Complex{T},1}, closed::Bool=true; opts...) where T
    x = real.(pts)
    y = imag.(pts)
    np = length(pts)


    kind = closed ? :closed : :open
    maxt = closed ? np+1 : np
    Sx = Spline(x,kind)
    Sy = Spline(y,kind)

    fx = funk(Sx)
    fy = funk(Sy)

    plot!(fx,fy,1,maxt;opts...)
end
