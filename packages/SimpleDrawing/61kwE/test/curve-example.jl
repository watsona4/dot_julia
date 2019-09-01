points = [
    3im
    1+im
    0im
    -1-im
    0-2im
    1.5+0.5im
    2im
    -1.5+0.5im
    0-2im
    1-im
    0im
    -1+im
]

function draw_curve_and_tangents(points)
    newdraw()
    draw_curve(points,color=:black,line=3)

    S = Spline(points,:closed)
    n = npatches(S)

    d = 1/3
    T = 1:d:n+1-d

    for t in T
        tt = t + d/3
        v = S'(tt)
        v /= 2*abs(v)
        draw_vector(v,S(tt),color=:green)
    end

    finish()
end

function tangent_plot(points)
    S = Spline(points,:closed)
    f(t) = angle(S'(t))/(2pi)
    plot(f,0.99,npatches(S)+1.01)
    plot!(legend=false)
end
