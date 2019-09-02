import Base: ==, convert, promote_rule, length, reverse, show, div

struct Line{T <: Number}
    m::Matrix{T}
    function Line{T}(m::Matrix{T}) where {T <: Number}
        @assert size(m) == (2, 2) "Invalid values."
        new(m)
    end
    Line{T}(lx::T, ly::T, rx::T, ry::T) where {T <: Number} =
        new(Matrix([lx rx; ly ry]))
end

Line(m::Matrix{T}) where {T <: Number} = Line{T}(m)

start(l::Line) = l.m[:, 1]
endof(l::Line) = l.m[:, 2]

@inline sx(l::Line) = l.m[1, 1]
@inline sy(l::Line) = l.m[2, 1]
@inline ex(l::Line) = l.m[1, 2]
@inline ey(l::Line) = l.m[2, 2]

area(::Line{T}) where {T <:Number} = zero(T)

function Line(lx::Number, ly::Number, rx::Number, ry::Number)
    t = promote(lx, ly, rx, ry)
    return Line{typeof(t[1])}(t...)
end

convert(::Type{Line{T}}, r::Line{S}) where {T <: Number, S <: Number} =
    Line{T}(Matrix{T}(r.m))

promote_rule(::Type{Line{T}}, ::Type{Line{S}}) where {T <: Number, S <: Number} =
    Line{promote_type(T, S)}

show(io::IO, r::Line) =
    print(io, "Line:[$(r.m[1, 1]) $(r.m[2, 1]) $(r.m[1, 2]) $(r.m[2, 2])]")

==(l1::Line{T}, l2::Line{T}) where {T <: Number} = all(iszero.(l1.m - l2.m))
==(l1::Line, l2::Line) = ==(promote(l1, l2)...)

function reverse(l::Line)
    m = copy(l.m)
    m[:, 1], m[:, 2] = m[:, 2], m[:, 1]
    return Line(m)
end

axis_parallel(l::Line{T}; dir::Int=1) where {T <: Number} =
    iszero(l.m[dir, 1] - l.m[dir, 2])

"""
```
    isHorizontal(l::Line) -> Bool
    isVertcal(l::Line) -> Bool
```
If the `Line` is horizontal or vertical.
"""
isHorizontal(l::Line) = axis_parallel(l, dir=2)
isVertical(l::Line)   = axis_parallel(l, dir=1)

"""
```
    length(l::Line) -> Float64
```
The length of the line segment.
"""
length(l::Line) = (v = l.m[:, 1] - l.m[:, 2]; sqrt(dot(v, v)))

"""
```
    ratio(l1::Line{T}, p::Vector{T}) -> r::Real
```
If `p` is on `l1` it divides the line at ratio `r:(1-r)` else nothing.
"""
function ratio(l::Line{T}, p::Vector{T}) where {T <: Real}
    dv = l.m[:, 2] - l.m[:, 1]
    dp = p - l.m[:, 1]
    r, c = !iszero(dv[1]) ? (dp[1] / dv[1], 1) : (dp[2] / dv[2], 2)
    if c == 1
        tp = dv[2]*r + l.m[2, 1]
        iszero(tp - p[2]) && return r
    else
        iszero(dp[1]) && return r
    end
    return nothing
end

ratio(l::Line{T}, p::Vector{S}) where {T <: Number, S <: Number} = 
    (ST = promote_type(S, T);
     ratio(convert(Line{ST}, l), convert(Vector{ST}, p)))

div(l::Line{T}, r::R) where {T <: Number, R <: Real} =
    l.m[:, 1]*(one(R) - r) + l.m[:, 2]*r

"""
```
    intersects(l1::Line{T}, l2::Line{T}) where {T <: Real} -> Bool
```
If `l1` and `l2` intersect each other. 
"""
function intersects(l1::Line{T}, l2::Line{T}) where T <: Real
    l = Matrix{Line{T}}(undef, 2, 2)
    l[1, 1] = l[2, 2] = l1
    l[1, 2] = l[2, 1] = l2

    l1l21 = parallelogram_area(hcat(l1.m, @view l2.m[:, 1]))
    l1l22 = parallelogram_area(hcat(l1.m, @view l2.m[:, 2]))
    l2l11 = parallelogram_area(hcat(l2.m, @view l1.m[:, 1]))
    l2l12 = parallelogram_area(hcat(l2.m, @view l1.m[:, 2]))
    t = [l1l21 l1l22; l2l11 l2l12]

    for i = 1:2
        for j = 1:2 
            if iszero(t[i, j])
                r = ratio(l[i, 1], l[i, 2].m[:, j])
                r === nothing && continue
                zero(T) <= notvoid(r) <= one(T) && return true
            end
        end
    end
    return t[1, 1]*t[1, 2] < zero(T) && t[2, 1]*t[2, 2] < zero(T)
end

intersects(l1::Line, l2::Line) = intersects(promote(l1, l2)...)

"""
```
    merge_axis_aligned(alines::Vector{Line{T}}, 
                       axis::Int=1, 
                       order::Symbol=:increasing,
                       tol::T=pcTol(T)) -> Vector{Line{T}}
```
Given an array of axis aligned lines, if the line ends touch or have an overlap
the lines are merged into a larger segment. Lines which are not touching the
other lines are left intact.

`order` parameter can be in `:increasing` or `:decreasing` order in the direction
of the axis. 

`axis` parameter can be `1` for horizontal lines and `2` for vertical lines. 
"""
function merge_axis_aligned(alines::Vector{Line{T}},
                            axis::Int=1,
                            order::Symbol=:increasing,
                            tol::T=pcTol(T)) where {T}
    length(alines) == 0 && return Line{T}[]
    pl = alines[1]
    m = copy(pl.m)
    oaxis = axis == 1 ? 2 : 1
    vl = Vector{Line{T}}()
    for i = 2:length(alines)
        l = alines[i]
        if iszero(l.m[oaxis, 1] - pl.m[oaxis, 1], tol)
            if order === :increasing && l.m[axis, 1] - pl.m[axis, 2] <= tol
                m[axis, 2] = max(l.m[axis, 2],  pl.m[axis, 2])
            elseif order === :decreasing && pl.m[axis, 1] - l.m[axis, 2] <= tol
                m[axis, 1] = min(l.m[axis, 1], pl.m[axis, 1])
            else
                push!(vl, Line{T}(m))
                m = copy(l.m)
            end
        else
            push!(vl, Line{T}(m))
            m = copy(l.m)
        end
        pl = l
    end
    push!(vl, Line{T}(m))
    return vl
end

function intersect_axis_aligned(hl::Line{T},
                                vl::Line{T}, tol::T) where T <: Number
    x, y  = sx(vl), sy(hl)
    if sx(hl) > ex(hl)
        hl = reverse(hl)
    end
    if sy(vl) > ey(vl)
        vl = reverse(vl)
    end
    if sx(hl) - tol <= x <= ex(hl) + tol && sy(vl) - tol <= y <= ey(vl) + tol
        return T[x, y]
    else
        return T[]
    end
end

function intersect_axis_aligned(hl::Line{T1},
                                vl::Line{T2},
                                tol::T=pcTol(T)) where {T1 <: Number,
                                                        T2 <: Number,
                                                        T <: Number}
    ST = promote_type(T1, T2, T)
    return intersect_axis_aligned(convert(Line{ST}, hl),
                                  convert(Line{ST}, vl),
                                  convert(ST, tol))
end

"""
    `isless` function  that can be used to sort horizonal lines in descending
    order (top to bottom).
"""
horiz_desc(l1::Line{T1},
           l2::Line{T2},
           tol::Union{T1, T2}=pcTol(promote_type(T1, T2))) where {T1 <: Number,
                                                                  T2 <: Number} =
    horiz_desc(convert(Line{promote_type(T1, T2)}, l1),
               convert(Line{promote_type(T1, T2)}, l2), tol)

@inline function horiz_desc(l1::Line{T}, l2::Line{T},
                            tol::T=pcTol(T)) where T <: Number
    dy = l1.m[2,1] - l2.m[2,1]
    dy > tol && return true
    return iszero(dy, tol) && l1.m[1, 1] - l2.m[1, 1] < -tol
end

"""
    `isless` function  that can be used to sort vertical lines in ascending
    order (left to right).
"""
vert_asc(l1::Line{T1},
         l2::Line{T2},
         tol::Union{T1, T2}=pcTol(promote_type(T1, T2))) where {T1 <: Number,
                                                                T2 <: Number} =
    vert_asc(convert(Line{promote_type(T1, T2)}, l1),
             convert(Line{promote_type(T1, T2)}, l2), tol)

@inline function vert_asc(l1::Line{T}, l2::Line{T},
                          tol::T=pcTol(T)) where T <: Number
    dx = l1.m[1,1] - l2.m[1,1]
    dx < -tol && return true
    return iszero(dx, tol) && l1.m[2, 2] - l2.m[2, 2] > tol
end
