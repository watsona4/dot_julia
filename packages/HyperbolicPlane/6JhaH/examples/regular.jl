using HyperbolicPlane, Plots

"""
`regular(n,r)` draw a regular `n`-gon in the hyperbolic plane.
The vertices are distance `r` from the origin.
"""
function regular(n::Int=5, r::Real=1.0)
    plot()
    pts = [ HPoint(r, (k/n)*2pi) for k=0:n ]
    for P in pts
        set_radius(P,3)
    end
    draw(pts)

    segs = [ HSegment(pts[k],pts[k+1]) for k=1:n ]
    draw(segs)
    draw(HPlane())
    finish()
end
