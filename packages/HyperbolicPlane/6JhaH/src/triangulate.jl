# functions to decompose a proper polygon into triangles
export triangulate

"""
`alt_mod(k,n)` is `mod(k,n)` unless the result is zero,
in which case we return `n`.
"""
function alt_mod(k::Int, n::Int)
    r = mod(k,n)
    return r==0 ? n : r
end

"""
`check_diagonal(X::HPolygon, k::Int)` checks to see if the diagonal
between vertices `k-1` and `k+1` (a) does not intersect the boundary of `X`
and (b) goes through the interior of `X`.
"""
function check_diagonal(X::HPolygon, k::Int)::Bool
    n = npoints(X)

    if n <= 3
        return true
    end

    kprev = alt_mod(k-1,n)
    knext = alt_mod(k+1,n)

    a = X.plist[kprev]
    b = X.plist[k]      # this is the current vertex (index k)
    c = X.plist[knext]

    dg = a+c  # this is the diagonal we're testing

    # check if ac contains a vertex (other than a or c)
    for i=1:n
        if i != kprev && i != knext
            v = X.plist[i]
            if in(v,dg)
                return false
            end
        end
    end

    # now check that ac doesn't intersect any of the sides of the polygon
    f(x) = alt_mod(x,n)
    exclude = [ f(k+j) for j=-2:1 ]
    for i=1:n
        if in(i,exclude)
            continue
        end
        S = X.plist[f(i)] +X.plist[f(i+1)]
        if meet_check(dg,S)
            return false
        end

    end

    # check that the diagonal is interior to X
    m = midpoint(dg)
    if !in(m,X)
        return false
    end

    return true
end

"""
`find_ear_diagonal(X::HPolygon)` returns an index `k` such that the
diagonal from `k-1` to `k+1` passes `check_diagonal`.
Returns `0` if no ear diagonal is found.
"""
function find_ear_diagonal(X::HPolygon)::Int
    for k=1:npoints(X)
        if check_diagonal(X,k)
            return k
        end
    end
    return 0
end

"""
`triangulate(X::HPolygon)` returns a list of triangles that
triangulate `X`. The polygon should have at least three sides, and
have no bad angles, and not self-intersect.
"""
function triangulate(X::HPolygon)::Array{HTriangle,1}
    n = npoints(X)

    if n < 3
        return HTriangle[]

    end

    if n == 3
        T = HTriangle(X)
        return [T]
    end


    k = find_ear_diagonal(X)

    if k==0
        @error "The polygon cannot be triangulated. Is it simple and proper?"
    end

    kprev = alt_mod(k-1,n)
    knext = alt_mod(k+1,n)
    a = X.plist[kprev]
    b = X.plist[k]
    c = X.plist[knext]
    T = a+b+c

    qlist = [ HPoint(X.plist[j]) for j=1:n if j!=k ]
    Y = HPolygon(qlist)
    result = triangulate(Y)
    pushfirst!(result, T)
    return result
end

"""
`area(X::HPolygon)` returns the area of the polygon, but is only
reliable if `X` does not self-intersect. See `is_simple`.
"""
function area(X::HPolygon)::Float64
    if npoints(X) < 3
        return 0.0
    end
    TT = triangulate(X)
    return sum(area(T) for T in TT)
end




# DEBUG STUFF

function draw_diagonal(X::HPolygon, k::Int)
    n = npoints(X)
    kprev = alt_mod(k-1,n)
    knext = alt_mod(k+1,n)
    a = X.plist[kprev]
    b = X.plist[knext]
    S = a+b
    set_line_style(S,:dot)
    draw(S)
end


function visualize(P::HPolygon)
    n = npoints(P)
    set_thickness(P,2)
    plot()
    draw(P)
    f(x) = alt_mod(x,n)
    for i=1:n
        a = P.plist[f(i-1)]
        ii = alt_mod(i+1,n)
        b = P.plist[ii]
        S = a+b
        if check_diagonal(P,i)
            set_color(S,:green)
        else
            continue
        end
        if in(midpoint(S),P)
            draw(S)
        end
    end

    for pt in P.plist
        draw(pt)
    end
    finish()
end
