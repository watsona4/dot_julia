using HyperbolicPlane, Plots

"""
`dual_tess()` draws dual tesselations of the hyperbolic plane.
The primal is a tiling by pentagons (drawn with solid lines)
and the dual is a tiling by quadrilaterals (drawn dotted).
"""
function dual_tess()
    C = tesselation(5,4,5)  # primal
    D = tesselation(4,5,5,true)  # dual

    # rotate all the pentagons 36 degrees
    r = rotation(pi/5)
    CC = [r(P) for P in C.objs]

    # make the dual quadrilaterals dotted
    for X in D.objs
        set_line_style(X,:dot)
    end

    plot()   # clear the screen
    draw(CC) # draw primal
    draw(D)  # draw dual
    finish()
end
