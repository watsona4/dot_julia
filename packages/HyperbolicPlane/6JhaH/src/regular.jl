# functions to create regular polygons

export equilateral, equiangular



"""
`_solver(f,goal,lo,hi)` assumes `f` is increasing on the interval `[lo,hi]`
"""
function _solver(f::Function, goal::Real, lo::Real, hi::Real)
    mid = (hi+lo)/2
    y = f(mid)

    if abs(y-goal) <= THRESHOLD*eps(1.0)
        return mid
    end
    if y > goal
        return _solver(f,goal,lo,mid)
    end
    return _solver(f,goal,mid,hi)
end

"""
`_solver(f,goal)` assumes that `f` is increasing and there is a nonnegative `x`
so that `f(x)==goal`.
"""
function _solver(f::Function, goal::Real)
    x::Float64 = 1.0
    while f(x) < goal
        x *= 2.0
    end
    _solver(f,goal,0,x)
end



"""
`equilateral(n,s)` creates a regular `n`-gon with side lengths `s`
centered at the origin. First point is on the positive x-axis.
"""
function equilateral(n::Int, s::Real)
    @assert n>2 "Number of sides must be at least 3"
    @assert s>0 "Side length must be positive"

    tlist = [ k*2*pi/n for k=0:n-1 ]   # list of angles
    t = tlist[2]

    f(x)  = dist(HPoint(x,0), HPoint(x,t))
    r = _solver(f,s)


    pts = [ HPoint(r,theta) for theta in tlist]

    return HPolygon(pts)
end

"""
`equiangular(n,theta)` creates a regular `n`-gon where the vertex
angles equal `theta`
"""
function equiangular(n::Int, theta::Real)
    @assert n>2 "Number of sides must be at least 3"
    if theta < 0
        theta = -theta
    end
    @assert theta!=0 "Angle cannot be zero"

    tmax = (n-2)*pi/n
    @assert theta<tmax "Angle must be less than $(n-2)*pi/$n = $tmax"

    tlist = [ k*2*pi/n for k=0:n-1 ]   # list of angles
    t = tlist[2]

    f(x) = -angle(HPoint(x,0), HPoint(x,t), HPoint(x,2t))
    r = _solver(f,-theta)

    pts = [ HPoint(r,theta) for theta in tlist]

    return HPolygon(pts)

end
