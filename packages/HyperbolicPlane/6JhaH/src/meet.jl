# Everything about intersecting
export meet_check, meet, ∧, stab_count, is_simple


"""
`meet_check(L::HLine,LL::HLine)` determines if two lines intersect.
Also for any combination of lines, segments, or rays.
"""
function meet_check(L::HLine, LL::HLine)::Bool
    if L == LL
        return false
    end
    s = L.s
    t = L.t
    ss = LL.s
    tt = LL.t

    if s < ss < t < tt
        return true
    end
    if ss < s < tt < t
        return true
    end
    return false
end


function meet_check(L::HLine, S::HSegment)::Bool
    LL = HLine(S)  # extend S
    if !meet_check(L,LL)
        return false
    end

    P = meet(L,LL)
    return in(P,S)
end

meet_check(S::HSegment,L::HLine)::Bool = meet_check(L,S)


function meet_check(S::HSegment, SS::HSegment)::Bool
    L = HLine(S)
    LL = HLine(SS)

    if L==LL  # see if they share exactly one endpoint
        A,B = endpoints(S)
        AA,BB = endpoints(SS)
        if A==AA && between(B,A,BB)
            return true
        end
        if A==BB && between(A,B,BB)
            return true
        end
        if B==AA && between(A,B,BB)
            return true
        end
        if B==BB && between(A,B,AA)
            return true
        end
        return false
    end

    if !meet_check(L,LL)
        return false
    end

    P = meet(L,LL)
    if in(P,S) && in(P,SS)
        return true
    end
    return false
end


function meet_check(L::HLine, R::HRay)::Bool
    LL = HLine(R)
    if !meet_check(L,LL)
        return false
    end
    P = meet(L,LL)
    return in(P,R)
end
meet_check(R::HRay, L::HLine)::Bool = meet_check(L,R)


function meet_check(R::HRay, S::HSegment)::Bool
    LR = HLine(R)
    LS = HLine(S)

    if LR == LS   # check if endpoints match up
        A,B = endpoints(S)
        X = get_vertex(R)
        if A==X
            return !in(B,R)
        end
        if B==X
            return !in(A,R)
        end
        return false
    end
    # R and S noncollinear
    if !meet_check(LR,LS)
        return false
    end
    P = meet(LR,LS)
    return in(P,R) && in(P,S)
end
meet_check(S::HSegment, R::HRay)::Bool = meet_check(R,S)

function meet_check(R::HRay, RR::HRay)::Bool
    L = HLine(R)
    LL = HLine(RR)

    if L==LL   # make sure same vertex, opposite directions
        if get_vertex(R) != get_vertex(RR)
            return false
        end
        if abs(R.t - RR.t) <= THRESHOLD * eps(1.0)
            return false
        end
        return true
    end

    if !meet_check(L,LL)
        return false
    end
    P = meet(L,LL)
    return in(P,R) && in(P,RR)
end


################################################################

"""
`meet(L,LL)` finds a point on lines `L` and `LL` or throws an
error if they don't intersect.  Also for a line and a segment, or
two segments.

See `meet_check`.
"""
function meet(L::HLine, LL::HLine)::HPoint
    @assert meet_check(L,LL) "The lines do not intersect"

    s = L.s   # artificially rotate to 0
    t = L.t
    ss = LL.s
    tt = LL.t

    a = exp(im*(t-s))
    b = exp(im*(ss-s))
    c = exp(im*(tt-s))

    A = real(in_up(a))
    B = real(in_up(b))
    C = real(in_up(c))

    R = abs(B-C)/2
    Z = (B+C)/2

    y = sqrt(R^2 - (A-Z)^2)

    p = up_in(A + im*y)*exp(im*s)

    return HPoint(p)
end

function meet(L::HLine, S::HSegment)::HPoint
    @assert meet_check(L,S) "The line and segment do not intersect at a unique point"
    p = meet(L, HLine(S))
    return p
end

meet(S::HSegment,L::HLine)::HPoint = meet(L,S)

function meet(S::HSegment,SS::HSegment)
    @assert meet_check(S,SS) "The segments do not intersect at a unique point"

    L = HLine(S)
    LL = HLine(SS)

    if L != LL
        p = meet(HLine(S),HLine(SS))
        return p
    end

    # special case: segments overlap in an end point
    A,B = endpoints(S)
    AA,BB = endpoints(SS)

    if A==AA || A==B
        return A
    end
    if B==AA || B==BB
        return B
    end
    # Should never get here
    @error "Programming error in meet(HSegment, HSegment)"
end


function meet(L::HLine, R::HRay)::HPoint
    @assert meet_check(L,R) "The line and ray do not intersect at a unique point"
    return meet(L, HLine(R))
end
meet(R::HRay, L::HLine)::HPoint = meet(L,R)


function meet(R::HRay, S::HSegment)::HPoint
    @assert meet_check(R,S) "The ray and segment do not intersect at a unique point"
    LR = HLine(R)
    LS = HLine(S)
    if LR != LS
        return meet(HLine(R, HLine(S)))
    end
    # must have an end of S as the common point
    A,B = endpoints(S)
    if in(A,R)
        return A
    end
    return B
end
meet(S::HSegment, R::HRay)::HPoint = meet(R,S)

function meet(R::HRay, RR::HRay)::HPoint
    @assert meet_check(R,RR) "The two rays do not instersect at a unique point"
    if HLine(R) == HLine(RR)
        return get_vertex(R)
    end
    return meet(HLine(R,HLine(RR)))
end


(∧)(L::HLinear, LL::HLinear)::HPoint = meet(L,LL)





"""
`stab_count(R,targets)` is used to count how many items in `targets` are
intersected by `R` where `targets` is a list of `HLinear` objects and `R`
is an `HLinear`.
"""
function stab_count(R::S, targets::Array{T,1}) where {S<:HLinear, T <: HLinear}
    count = 0
    nt = length(targets)
    for j = 1:nt
        if meet_check(R,targets[j])
            count += 1
        end
    end
    return count
end


"""
`in(p::HPoint, X::HPolygon)` determines if the point lies on the boundary or,
or is interior to, the polygon. Be sure that `polygon_check(X)` and
`is_simple(X)` both return `true`.
"""
function in(p::HPoint, X::HPolygon)::Bool
    for a in X.plist
        if p==a
            return true
        end
    end

    ss = sides(X)
    for s in ss
        if in(p,s)
            return true
        end
    end

    # Get a ray that doesn't go through a vertex (and therefore not through a side)
    R = RandomHRay(p)
    while true
        for a in X.plist
            if in(a,R)
                R = RandomHRay()
                continue
            end
        end
        break
    end

    return stab_count(R,ss)%2 == 1
end
