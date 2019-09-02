using HyperbolicPlane, Plots

function circle_example()
    P = HPoint(1,pi/6)
    C = HCircle(P,1.5)
    X,Y,Z = points_on_circle(C)
    T = X+Y+Z
    set_color(T,:red)
    set_radius(P,2)
    L1 = bisector(X,Y)
    L2 = bisector(X,Z)
    L3 = bisector(Y,Z)
    set_color(L1,:green)
    set_color(L2,:green)
    set_color(L3,:green)
    plot()
    draw(C,T,L1,L2,L3,P,HPlane())
    finish()
end


function rand_circle_example()
    X,Y,Z = [ RandomHPoint() for j=1:3 ]
    C = HCircle()
    try
        C = HCircle(X,Y,Z)
    catch
        println("Sorry: The three points we generated are not contained in a common circle")
        println("Please try again")
        return
    end
    set_thickness(C,2)
    P = get_center(C)

    T = X+Y+Z
    set_color(T,:red)
    set_radius(P,2)
    L1 = bisector(X,Y)
    L2 = bisector(X,Z)
    L3 = bisector(Y,Z)
    set_color(L1,:green)
    set_color(L2,:green)
    set_color(L3,:green)

    plot()
    draw(C,T,L1,L2,L3,P,HPlane())
    finish()
end
