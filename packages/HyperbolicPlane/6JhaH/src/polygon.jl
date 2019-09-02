export HPolygon, add_point!, npoints, RandomHPolygon, sides
export polygon_check

"""
`HPolygon()` creates a new polygon (with no points).

`HPolygon(list)` creates a polygon whose points are specified in `list`.

See: `add_point!`
"""
struct HPolygon <: HObject
    plist::Array{HPoint,1}
    attr::Dict{Symbol,Any}
    function HPolygon()
        X = new(HPoint[],Dict{Symbol,Any}())
        set_color(X)
        set_thickness(X)
        set_line_style(X)
        return X
    end
end


"""
`add_point!(X::HPolygon, P::HPoint)` adds the point `P`
as the last point of the polygon `X`
"""
add_point!(X::HPolygon, P::HPoint) = push!(X.plist,P)

"""
`endpoints(X::HPolygon)` returns the list of vertices (in order)
of the polygon.
"""
endpoints(X::HPolygon) = deepcopy(X.plist)


"""
`sides(P:::HPolygon/HTriangle)` returns a list of the line segments
that are the sides of the polygon.
"""
function sides(X::HPolygon)::Array{HSegment,1}
    n = npoints(X)
    if n < 2
        return HSegment[]
    end

    result = Array{HSegment,1}(undef,n)
    for k=1:n-1
        a = X.plist[k]
        b = X.plist[k+1]
        result[k] = a+b
    end
    result[end] = X.plist[end] + X.plist[1]
    return result
end

sides(T::HTriangle) = sides(HPolygon(T))


"""
`npoints(X::HPolygon)` returns the number of points on the polygon.
"""
npoints(X::HPolygon) = length(X.plist)

function HPolygon(pts::Array{HPoint,1})
    X = HPolygon()
    for p in pts
        add_point!(X,p)
    end
    return X
end

HPolygon(pts...) = HPolygon(collect(pts))
HPolygon(X::HPolygon) = HPolygon(X.plist)  # copy constructor

"""
`polygon_check(X::HPolygon,quiet=true)` checks that the polygon is nondegenerate.
Possible degeneracies are:
+ Repeated vertices
+ Fewer than three distinct vertices
+ Angles that are either 0 degrees or 180 degrees
If `quiet` is `false`, then a reason for the failed check is printed.
"""
function polygon_check(X::HPolygon, quiet::Bool=true)::Bool

    # Check that the endpoints are all distinct
    n = npoints(X)

    C = HContainer(X.plist...)
    if length(C) != n
        quiet || println("The polygon has repeated vertices")
        return false
    end

    if length(C) < 3
        quiet || println("The polygon is degenerate (fewer than 3 distinct vertices)")
        return false
    end

    angs = angles(X)
    zero_angs = angs .< (THRESHOLD * eps(1.0))
    if any(zero_angs)
        quiet || println("The polygon has 0-degree angles")
        return false
    end

    big_angs = angs .> (pi - THRESHOLD*eps(1.0))
    if any(big_angs)
        quiet || println("The polygon has 180-degree angles")
        return false
    end

    return true
end






function HPolygon(T::HTriangle)
    a,b,c = endpoints(T)
    return HPolygon(a,b,c)
end


function HTriangle(X::HPolygon)
    @assert npoints(X)==3 "Can only convert a 3-point HPolygon into an HTriangle"
    return HTriangle(X.plist...)
end

"""
`RandomHPolygon(n::Int,simple::Bool=false)` create a new `HPolygon` with
`n` points chosen at random. With `simple` set to `true`, return a polygon
that does not self-intersect.
"""
function RandomHPolygon(n::Int, simple::Bool=false)
    @assert n>=0 "Number of vertices must be nonnegative"
    if simple && n>3
        P = RandomHPolygon(n)
        while !is_simple(P)
            P = RandomHPolygon(n)
        end
        return P
    end

    pts = [ RandomHPoint() for j=1:n ]
    return HPolygon(pts)
end

"""
`angles(P::HPolygon)` returns a list of the angles at the vertices of `P`.

+ The results are always in the interval `[0,pi]`.
+ The order of the angles is the order of the vertices in `P.plist`.
"""
function angles(P::HPolygon)::Array{Float64,1}
    n = npoints(P)
    result = zeros(Float64,n)
    if n < 3
        return result
    end

    # first angle
    result[1] = angle(P.plist[end],P.plist[1],P.plist[2])

    for j=2:n-1
        result[j] = angle(P.plist[j-1], P.plist[j], P.plist[j+1])
    end

    result[n] = angle(P.plist[n-1],P.plist[n],P.plist[1])

    return result
end


function perimeter(P::HPolygon)
    n = npoints(P)
    if n < 2
        return 0.0
    end
    result = dist(P.plist[1],P.plist[end])
    if n==2
        return 2*result
    end
    for j=1:n-1
        result += dist(P.plist[j],P.plist[j+1])
    end
    return result
end



function show(io::IO,X::HPolygon)
    print(io,"HPolygon with $(npoints(X)) points")
end

# require 0 <= k < n
"""
`_cycle(A,k)` returns a `k`-step shift of `A`. We require
`k` to be in the interval `[0,n-1]` where `n=length(A)`.
No checking is done.
"""
function _cycle(A::Array{T,1}, k::Int) where T
    n = length(A)
    B = Array{T,1}(undef,n)
    for t = 1:n-k
        @inbounds B[t] = A[t+k]
    end
    for t = 1:k
        @inbounds B[n-k+t] = A[t]
    end
    return B
end

"""
`_cyclic_equal(A,B)` checks if some cyclic shift of one list
equals the other.
"""
function _cyclic_equal(A::Array{S,1}, B::Array{T,1}) where {S,T}
    n = length(A)
    if length(B) != n
        return false
    end
    for s=0:n-1
        if A == _cycle(B,s)
            return true
        end
    end
    return false
end

(==)(X::HPolygon, Y::HPolygon) = _cyclic_equal(X.plist, Y.plist) ||
    _cyclic_equal(X.plist,reverse(Y.plist))



"""
`is_simple(X::HPolygon)` determines if the polygon edges do not self-intersect.
Be sure the polygon is legit using `polygon_check` first.
"""
function is_simple(X::HPolygon)
    n = npoints(X)
    if n <= 3
        return true   # triangles are fine
    end
    slist = sides(X)
    for i=1:n-2
        for j=i+2:n
            if i==1 && j==n
                continue
            end
            if meet_check(slist[i], slist[j])
                return false
            end
        end
    end
    return true
end
