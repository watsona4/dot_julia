using HyperbolicPlane, Plots

"""
`complete_graph(n,rad=2)` draws the complete graph
on `n` vertices in the Hyperbolic plane (using straight line
segments for edges). The vertices are distance `rad` from the
origin.
"""
function complete_graph(n::Int=5, radius::Real = 2)

    if n <= 0
        throw(DomainError(n,"n must be positive"))
    end


    pts = [ HPoint(radius, 2pi*k/n) for k=1:n ]
    plot()
    for j=1:n-1
        for k=j+1:n
            L = HSegment(pts[j], pts[k])
            draw(L)
        end
    end

    for j=1:n
        P = pts[j]
        set_radius(P,2)
        draw(P)
    end
    draw(HPlane())
    finish()
end
