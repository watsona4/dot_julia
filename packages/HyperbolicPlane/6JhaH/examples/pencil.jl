using HyperbolicPlane, Plots

"""
`pencil(s::Real, nlines::Int, ncycles::Int)` draws a pencil of `nlines`
lines with common ideal point `exp(im*s)` and `ncycles` Horocycles that
are orthogonal to those lines.
"""
function pencil(s::Real=1, nlines::Int=5, ncycles::Int=5)
    plot()

    # draw a pencil of lines
    tlist = [ 2*pi*k/(nlines+1) for k=1:nlines ]
    for t in tlist
        draw(HLine(s, s+t))
    end

    # draw a pencil of horocycles
    xlist = [ 2*t/(ncycles+1) - 1 for t in 1:ncycles]

    plist = [ HPoint(x+0im) for x in xlist ]
    f = rotation(s)
    for P in plist
        H = Horocycle(f(P), s)
        draw(H)
    end
    draw(HPlane())
    finish()
end
