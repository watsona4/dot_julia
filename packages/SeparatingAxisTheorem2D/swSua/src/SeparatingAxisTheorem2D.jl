module SeparatingAxisTheorem2D

using LinearAlgebra
using StaticArrays
using CoordinateTransformations
using RecipesBase
import StaticArrays: SUnitRange

export Shape2D, AxisAlignedBoundingBox, AABB, LineSegment, Polygon, Triangle, Circle, CompoundShape
export intersecting, inflate, sweep, sweep_intersecting

# Utilities
   norm2(v)    = v⋅v
    perp(v)    = SVector(v[2], -v[1])
 project(v, w) = w*(v⋅w)/(w⋅w)
projectN(v, w) = w*(v⋅w)
 reflect(v, a) = v - 2*project(v, a)
reflectN(v, a) = v - 2*projectN(v, a)
  rotate(v, θ) = ((s, c) = sincos(θ); SVector(v[1]*c - v[2]*s, v[1]*s + v[2]*c))
  ccw(a, b, c) = (b - a)×(c - a) > 0

projectNextrema(pts, n)    = SVector{2}(extrema(p⋅n for p in pts))
voronoi_region(p, v)       = (d = p⋅v; ifelse(d < 0, -1, ifelse(d > v⋅v, 1, 0)))
overlapping(I1, I2)        = I1[1] <= I2[2] && I2[1] <= I1[2]
ininterval(x, I)           = I[1] <= x <= I[2]
enclosing_interval(I1, I2) = SVector(min(I1[1], I2[1]), max(I1[2], I2[2]))
minmaxV((x,y))             = SVector(minmax(x, y))
minmaxV(x, y)              = SVector(minmax(x, y))
wrap1(i, N)                = ifelse(i < 1, N, ifelse(i > N, 1, i))

  circshift1(v::StaticVector{N}) where {N} = pushfirst(v[SUnitRange(1,N-1)], v[end])
uncircshift1(v::StaticVector{N}) where {N} = push(v[SUnitRange(2,N)], v[1])
@generated function unrolled_any(f, ::Val{N}) where {N}
    N == 0 ? false : :(Base.@_inline_meta; $(foldr((x, y) -> :($x || $y), [:(f($i)) for i in 1:N])))
end
@generated function unrolled_all(f, ::Val{N}) where {N}
    N == 0 ? true  : :(Base.@_inline_meta; $(foldr((x, y) -> :($x && $y), [:(f($i)) for i in 1:N])))
end
@inline unrolled_any(f, tup::NTuple{N,Any}) where {N} = unrolled_any(i -> (Base.@_inline_meta; f(tup[i])), Val(N))
@inline unrolled_all(f, tup::NTuple{N,Any}) where {N} = unrolled_all(i -> (Base.@_inline_meta; f(tup[i])), Val(N))

# Shape Definitions
const Point = AbstractVector{<:Number}
abstract type Shape2D{T} end
abstract type AbstractPolygon{T} <: Shape2D{T} end
## BoundingBox
struct AxisAlignedBoundingBox{T} <: AbstractPolygon{T}
    bounds::SMatrix{2,2,T,4}
end
AxisAlignedBoundingBox((xl, xu), (yl, yu)) = AxisAlignedBoundingBox(SMatrix{2,2}(xl, yl, xu, yu))
AxisAlignedBoundingBox(x::Number, y::Number) = AxisAlignedBoundingBox(SMatrix{2,2}(-x/2, -y/2, x/2, y/2))
const AABB{T} = AxisAlignedBoundingBox{T}
Base.getindex(B::AABB, i, j=:) = B.bounds[i,j]
getAABB(aabb::AABB) = aabb
getAABB(X::Shape2D) = X.aabb
getAABB((x, y)::Point) = AABB((x, x), (y, y))

## Line Segments
abstract type AbstractLineSegment{T} <: AbstractPolygon{T} end
### SimpleLineSegment
struct SimpleLineSegment{T} <: AbstractLineSegment{T}
    v   ::SVector{2,T}
    w   ::SVector{2,T}
    edge::SVector{2,T}
    aabb::AABB{T}

    SimpleLineSegment{T}(v, w) where {T} = new(v, w, w - v, AABB(minmax(v[1], w[1]), minmax(v[2], w[2])))
end
SimpleLineSegment(v, w) = (T = eltype(v); SimpleLineSegment{T}(SVector{2,T}(v), SVector{2,T}(w)))

### LineSegment
struct LineSegment{T} <: AbstractLineSegment{T}
    v     ::SVector{2,T}
    w     ::SVector{2,T}
    edge  ::SVector{2,T}
    normal::SVector{2,T}
    ndotv ::T
    aabb  ::AABB{T}

    function LineSegment{T}(v, w; normalize_normals=false) where {T}
        edge   = w - v
        normal = normalize_normals ? normalize(perp(edge)) : perp(edge)
        ndotv  = normal⋅v
        aabb   = AABB(minmax(v[1], w[1]), minmax(v[2], w[2]))
        new(v, w, edge, normal, ndotv, aabb)
    end
end
LineSegment(v, w) = (T = eltype(v); LineSegment{T}(SVector{2,T}(v), SVector{2,T}(w)))

## Polygon
struct Polygon{N,T} <: AbstractPolygon{T}
    points  ::SVector{N,SVector{2,T}}
    edges   ::SVector{N,SVector{2,T}}
    normals ::SVector{N,SVector{2,T}}
    nextrema::SVector{N,SVector{2,T}}
    aabb    ::AABB{T}

    function Polygon{N,T}(points; normalize_normals=false) where {N,T}
        edges    = uncircshift1(points) .- points
        normals  = normalize_normals ? normalize.(perp.(edges)) : perp.(edges)
        nextrema = projectNextrema.(Ref(points), normals)
        @assert last.(nextrema) ≈ dot.(points, normals) "Polygon must be convex"
        aabb     = AABB(extrema(first.(points)), extrema(last.(points)))
        new(points, edges, normals, nextrema, aabb)
    end
end
Polygon(points) = (N = length(points); T = eltype(eltype(points)); Polygon{N,T}(SVector{N,SVector{2,T}}(points)))
Polygon(points...) = Polygon(points)
Polygon(B::AABB) = Polygon(SVector.(B[1][SVector(1,2,2,1)], B[2][SVector(1,1,2,2)]))

## Triangle
Triangle((P1, P2, P3)) = ccw(P1, P2, P3) ? Polygon(P1, P2, P3) : Polygon(P1, P3, P2)
Triangle(points...) = Triangle(points)

## Circle
struct Circle{T} <: Shape2D{T}
    c::SVector{2,T}
    r::T
    r2::T
    aabb::AABB{T}

    function Circle{T}(c, r) where {T}
        @assert r > 0 "Circle radius $r must be positive"
        aabb = AABB((c[1] - r, c[1] + r), (c[2] - r, c[2] + r))
        new(c, r, r*r, aabb)
    end
end
Circle(c, r) = (T = eltype(c); Circle{T}(SVector{2,T}(c), T(r)))
Circle(r) = (T = eltype(r); Circle{T}(zeros(SVector{2,T}), r))

## Compound Shapes
struct CompoundShape{PS,T} <: Shape2D{T}
    parts::PS
    aabb ::AABB{T}

    function CompoundShape{PS,T}(parts) where {PS,T}
        aabb = AABB((minimum(getAABB(P)[1,1] for P in parts), maximum(getAABB(P)[1,2] for P in parts)),
                    (minimum(getAABB(P)[2,1] for P in parts), maximum(getAABB(P)[2,2] for P in parts)))
        new(parts, aabb)
    end
end
CompoundShape(parts::Shape2D{T}...) where {T} = CompoundShape{typeof(parts),T}(parts)
CompoundShape(parts::Vector{S}) where {T,S<:Shape2D{T}} = CompoundShape{Vector{S},T}(parts)

# Projecting Shapes onto Axes
projectNextrema(B::AABB,                n) = minmaxV(n[1].*B[1]) + minmaxV(n[2].*B[2])
projectNextrema(L::AbstractLineSegment, n) = minmaxV(L.v⋅n, L.w⋅n)
projectNextrema(P::Polygon,             n) = projectNextrema(P.points, n)
projectNextrema(C::Circle,              n) = (d = C.c⋅n; r = C.r*norm(n); SVector(d - r, d + r))

# Separating Axis
## General Method (unused?)
separating_axis(S1::Shape2D, S2::Shape2D, a) = !overlapping(projectNextrema(S1, a), projectNextrema(S2, a))
## Specialized Methods (axis corresponding to first shape)
separating_axis(L::LineSegment, S::Shape2D) = !ininterval(L.ndotv, projectNextrema(S, L.normal))
separating_axis(P::Polygon, S::Shape2D, i::Integer) = !overlapping(P.nextrema[i], projectNextrema(S, P.normals[i]))

# Intersection Checking
intersecting(X, Y) = !AABBseparated(X, Y) && _intersecting(X, Y)
intersecting(X, Y, f) = intersecting(X, f(Y))
## Special Cases (Point/AABB)
intersecting(B1::AABB, B2::AABB)  = overlapping(B1[1], B2[1]) && overlapping(B1[2], B2[2])
intersecting( p::Point, B::AABB)  = ininterval(p[1], B[1]) && ininterval(p[2], B[2])
intersecting( B::AABB,  p::Point) = intersecting(p, B)

## Broadphase
AABBseparated(S1::Shape2D, S2::Shape2D) = !intersecting(getAABB(S1), getAABB(S2))
AABBseparated( p::Point,    S::Shape2D) = !intersecting(p, getAABB(S))
AABBseparated( S::Shape2D,  p::Point)   = AABBseparated(p, S)

## Narrowphase - Point
_intersecting(p::Point, L::LineSegment{T}) where {T} = (x = p - L.v; e = L.edge; abs(x×e) < eps(T) && 0 <= x⋅e <= e⋅e)
# _intersecting(p::Point, P::Polygon) = all(ininterval(p⋅n, I) for (n, I) in zip(P.normals, P.nextrema))
_intersecting(p::Point, P::Polygon{N}) where {N} = unrolled_all(i -> ininterval(p⋅P.normals[i], P.nextrema[i]), Val(N))
_intersecting(p::Point, C::Circle) = norm2(p - C.c) <= C.r2
_intersecting(S::Union{LineSegment,Polygon,Circle}, p::Point) = _intersecting(p, S)

## Narrowphase - AbstractPolygon (AABB/LineSegment/Polygon)
_intersecting(X::AbstractPolygon, Y::AbstractPolygon) = !_any_separating_axis(X, Y) && !_any_separating_axis(Y, X)
_any_separating_axis(B::AABB,        S::Shape2D) = false # established by !AABBseparated by this point
_any_separating_axis(L::LineSegment, S::Shape2D) = separating_axis(L, S)
# _any_separating_axis(P::Polygon{N},  S::Shape2D) where {N} = any(separating_axis(P, S, i) for i in 1:N)
_any_separating_axis(P::Polygon{N},  S::Shape2D) where {N} = unrolled_any(i -> separating_axis(P, S, i), Val(N))

## Narrowphase - AbstractLineSegment (SimpleLineSegment, LineSegment)
_intersecting(L1::AbstractLineSegment, L2::AbstractLineSegment) = ccw(L1.v, L2.v, L2.w) != ccw(L1.w, L2.v, L2.w) &&
                                                                  ccw(L1.v, L1.w, L2.v) != ccw(L1.v, L1.w, L2.w)

## Narrowphase - Circle
_intersecting(C::Circle, B::AABB) = _intersecting(clamp.(C.c, B[:,1], B[:,2]), C)
function _intersecting(C::Circle, L::AbstractLineSegment)
    _intersecting(L.v, C) && return true
    _intersecting(L.w, C) && return true
    vc = C.c - L.v
    d2 = norm2(L.edge)
    d2*C.r2 < (L.edge×vc)^2 && return false
    0 <= vc⋅L.edge <= d2
end
function _intersecting(C::Circle, P::Polygon{N}) where {N}
    for i in 1:N
        pi2c = C.c - P.points[i]
        vr = voronoi_region(pi2c, P.edges[i])
        if vr == 0
            pi2c⋅P.normals[i] > C.r*norm(P.normals[i]) && return false
        else
            j = wrap1(i + vr, N)
            pj2c = C.c - P.points[j]
            vr*voronoi_region(pj2c, P.edges[j]) < 0 && norm2(ifelse(vr > 0, pj2c, pi2c)) > C.r2 && return false
        end
    end
    true
end
_intersecting(X::AbstractPolygon, C::Circle) = _intersecting(C, X)
_intersecting(C1::Circle, C2::Circle) = norm2(C1.c - C2.c) <= (C1.r + C2.r)^2

## Compound Shape Narrowphase
_intersecting(X::Union{Point,Shape2D}, S::CompoundShape) = any(P -> intersecting(X, P), S.parts)
_intersecting(X::Union{Point,Shape2D}, S::CompoundShape{<:Tuple}) = unrolled_any(P -> intersecting(X, P), S.parts)
_intersecting(S::CompoundShape, X::Union{Point,AbstractPolygon,Circle}) = _intersecting(X, S)

# Transformations
## Inflation
inflate(p::Point, ε; round_corners=true) = Circle(p, ε)
inflate(B::AABB,  ε; round_corners=true) = inflate(Polygon(B), ε, round_corners=round_corners)
function inflate(L::AbstractLineSegment, ε; round_corners=true)
    n = normalize(L isa LineSegment ? L.normal : perp(L.edge))
    if round_corners
        CompoundShape(Polygon(SVector(L.v + ε*n, L.w + ε*n, L.w - ε*n, L.v - ε*n)), Circle(L.v, ε), Circle(L.w, ε))
    else
        m = perp(n)
        Polygon(SVector(L.v + ε*(n + m), L.w + ε*(n - m), L.w + ε*(-n - m), L.v + ε*(-n + m)))
    end
end
function inflate(P::Polygon, ε; round_corners=true)
    push_out_corner_vector(n0, n1) = (c = n0×n1; abs(c) < 1e-6 ? n0 : (perp(n1) - perp(n0))/c)
    normals = normalize.(P.normals)
    !round_corners && return Polygon(P.points .+ ε.*push_out_corner_vector.(circshift1(normals), normals))
    CompoundShape(
        Polygon(vec([P.points .+ ε.*circshift1(normals) P.points .+ ε.*normals]')),
        Circle.(P.points, Ref(ε))...
    )
end
inflate(C::Circle,        ε; round_corners=true) = Circle(C.c, C.r + ε)
inflate(S::CompoundShape, ε; round_corners=true) = CompoundShape(inflate.(S.parts, Ref(ε), round_corners=round_corners))

## Affine Transformation
(f::Translation)(S::Shape2D) = transform(f, S)    # julia#14919 --> AbstractAffineMap
(f::LinearMap)(S::Shape2D)   = transform(f, S)
(f::AffineMap)(S::Shape2D)   = transform(f, S)
transform(f::Translation,                B::AABB)          = AABB(B.bounds .+ f.translation)
transform(f::Union{LinearMap,AffineMap}, B::AABB)          = transform(f, Polygon(B))
transform(f::AbstractAffineMap,          L::LineSegment)   = LineSegment(f(L.v), f(L.w))
transform(f::AbstractAffineMap,          P::Polygon)       = Polygon(f.(P.points))
transform(f::Translation,                C::Circle)        = Circle(f(C.c), C.r)
transform(f::Union{LinearMap,AffineMap}, C::Circle)        = Circle(f(C.c), norm(f.linear[:,1]))    # isometries only
transform(f::AbstractAffineMap,          S::CompoundShape) = CompoundShape(f.(S.parts))

## Sweep
sweep(X, f1, f2) = sweep(f1(X), f2(X))
sweep(v::Point, w::Point) = LineSegment(v, w)
sweep(B1::AABB, B2::AABB) = sweep(Polygon(B1), Polygon(B2))
function sweep(L1::AbstractLineSegment, L2::AbstractLineSegment; check_degenerate=false)
    if intersecting(L1, L2)
        λ = [L1.edge L2.edge]\(L2.v - L1.v)
        p = L1.v + λ[1]*L1.edge
        if ccw(L1.v, L2.v, p)
            CompoundShape(Polygon(L1.v, L2.v, p), Polygon(L1.w, L2.w, p))
        else
            CompoundShape(Polygon(L2.v, L1.v, p), Polygon(L2.w, L1.w, p))
        end
    else
        if check_degenerate
            V, W = SimpleLineSegment(L1.v, L2.v), SimpleLineSegment(L1.w, L2.w)
            intersecting(V, W) && return sweep(V, W)
        end
        a = ccw(L1.v, L1.w, L2.w)
        b = ccw(L1.w, L2.w, L2.v)
        c = ccw(L2.w, L2.v, L1.v)
        d = ccw(L2.v, L1.v, L1.w)
        if a == c
            CompoundShape(Triangle(L1.v, L1.w, L2.w), Triangle(L2.w, L2.v, L1.v))
        else # b == d
            CompoundShape(Triangle(L1.w, L2.w, L2.v), Triangle(L2.v, L1.v, L1.w))
        end
    end
end
sweep(P1::Polygon, P2::Polygon) = CompoundShape(P1, sweep.(SimpleLineSegment.(P1.points, uncircshift1(P1.points)),
                                                           SimpleLineSegment.(P2.points, uncircshift1(P2.points)))...)
sweep(C1::Circle,  C2::Circle)  = inflate(SimpleLineSegment(C1.c, C2.c), C1.r, round_corners=true)
sweep(S1::CompoundShape, S2::CompoundShape) = CompoundShape(sweep.(S1.parts, S2.parts)...)

# Sweep Intersection Checking
combined_AABB(X, Y) = (BX = getAABB(X); BY = getAABB(Y); AABB([min.(BX[:,1], BY[:,1]) max.(BX[:,2], BY[:2])]))
## X Static, Y Dynamic
sweep_intersecting(X, Y, f1, f2) = sweep_intersecting(X, f1(Y), f2(Y))
sweep_intersecting(X, Y1, Y2) = !AABBseparated(X, combined_AABB(Y1, Y2)) && _sweep_intersecting(X, Y1, Y2)

_sweep_intersecting(X, Y1, Y2) = intersecting(X, sweep(Y1, Y2))

## X and Y Dynamic
sweep_intersecting(X, fX1, fX2, Y, fY1, fY2) = sweep_intersecting(X, Y, inv(fX1) ∘ fY1, inv(fX2) ∘ fY2)

# Distance Computation
## TODO: port over from old MotionPlanning.jl code

# Plot Recipes
@recipe function f(B::AABB; dims=(1,2))
    seriestype :=  :shape
    fillcolor  --> :match
    linecolor  --> :match
    label      --> ""
    x, y = dims
    coords = (B[1][SVector(1,2,2,1)], B[2][SVector(1,1,2,2)])
    coords[x], coords[y]
end

@recipe function f(L::AbstractLineSegment; dims=(1,2))
    seriestype :=  :shape
    fillcolor  --> :match
    linecolor  --> :match
    label      --> ""
    x, y = dims
    SVector(L.v[x], L.w[x]), SVector(L.v[y], L.w[y])
end

@recipe function f(P::Polygon; dims=(1,2))
    seriestype :=  :shape
    fillcolor  --> :match
    linecolor  --> :match
    label      --> ""
    x, y = dims
    getindex.(P.points, x), getindex.(P.points, y)
end

@recipe function f(C::Circle; dims=(1,2), n=64)
    seriestype :=  :shape
    fillcolor  --> :match
    linecolor  --> :match
    label      --> ""
    x, y = dims
    θ = range(-π, stop=π, length=n)
    C.c[x] .+ C.r*cos.(θ), C.c[y] .+ C.r*sin.(θ)
end

@recipe f(S::CompoundShape; dims=(1,2)) = (dims --> dims; foreach(P -> @series(begin P end), S.parts))

end # module
