using Plots, HyperbolicPlane, SimpleDrawing



function tritest(X::HPolygon)
    set_thickness(X,3)
    set_color(X,:blue)
    TT = triangulate(X)
    plot()
    draw(TT)
    draw(X)
    for p in X.plist
        a = HPoint(p)
        set_color(a,:red)
        set_radius(a,1.5)
        draw(a)
    end
    finish()
end
