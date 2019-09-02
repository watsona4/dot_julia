using HyperbolicPlane, Plots

"""
`concentric()` draws a picture of several concentric circles.
"""
function concentric()
    P = HPoint(1,pi/6)
    for r in 0.25:0.25:3
        C = HCircle(P,r)
        draw(C)
    end
    draw(HPlane())
    finish()
end
