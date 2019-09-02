# These functions set visual attributes of HObjects

export set_color, set_radius, set_thickness, set_line_style
export set_fill_alpha, set_fill_color, set_no_fill

export copy_attr

"""
`set_color(X,col)` sets the color of the hyperbolic object `X`.
"""
function set_color(P::HPoint, col=:black)
    P[:markercolor] = col
    P[:markerstrokecolor] = col
    nothing
end

function set_color(P::HObject, col=:black)
    P[:linecolor] = col
end

"""
`set_radius(P,rad)` sets the radius for an `HPoint`.
The default is 1.
"""
function set_radius(P::HPoint, rad=1)
    P[:marker] = rad
end

"""
`set_thickness(X,thk)` sets the thickness of the line used
to draw the hyperbolic object `X`. Default is 1.
"""
function set_thickness(P::HObject, thk = 1)
    P[:linewidth] = thk
end

"""
`set_line_style(X,style)` sets the line style for drawing
`X`. Default is `:solid`.
"""
function set_line_style(P::HObject, style = :solid)
    P[:linestyle] = style
end


"""
`set_fill_color(X,col)` sets the color used to fill
`X`. Works for `HPlane` and `HCircle`. Default is `:yellow`
"""
function set_fill_color(P::HRound, col = :yellow)
    P[:fillrange] = 1
    P[:fillcolor] = col
end

"""
`set_fill_alpha(X,alpha)` sets the alpha value for the object's
fill. Only works for `HPlane` and `HCircle`. Default value is 1
(not transparent)
"""
function set_fill_alpha(P::HRound, alf = 1)  # 1 = solid color
    P[:fillalpha] = alf
end

"""
`set_no_fill(X)` removes fill from the `HObject`. It now
draws as unfilled.
"""
function set_no_fill(P::HRound)
    delete!(P.attr,:fillcolor)
    delete!(P.attr,:fillalpha)
    delete!(P.attr,:fillrange)
    nothing
end


"""
`copy_attr(A,B)` copies the attributes assigned to `B` into `A`.
"""
function copy_attr(A::HObject, B::HObject)
    for k in keys(B.attr)
        A[k] = B[k]
    end
end
