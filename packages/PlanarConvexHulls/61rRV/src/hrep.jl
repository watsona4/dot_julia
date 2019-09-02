const hrep_doc = """
Return the equivalent halfspace representation of the convex hull, i.e.
matrix ``A`` and vector ``b`` such that the set of points inside the hull
is

```math
\\left\\{ x \\mid A x \\le b \\right\\}
```
"""

"""
$(SIGNATURES)

$hrep_doc

If `hull` is backed by a statically sized vector of vertices, the output `(A, b)`
will be statically sized as well. If the vector of vertices is additionally
immutable (e.g., a `StaticArrays.SVector`), then `hrep` will not perform any
dynamic memory allocation.
"""
hrep(hull::ConvexHull) = _hrep(hull, Length(vertices(hull)))

function _hrep(hull::ConvexHull, ::Length{N}) where N
    T = eltype(hull)
    R = arithmetic_closure(T)
    vertices = hull.vertices
    if N === StaticArrays.Dynamic()
        n = length(vertices)
        A = similar(vertices, R, n, 2)
        b = similar(vertices, R, n)
        hrep!(A, b, hull)
        return A, b
    else
        Amut = similar(vertices, R, Size(N, 2))
        bmut = similar(vertices, R, Size(N))
        hrep!(Amut, bmut, hull)
        A = convert(similar_type(vertices, R, Size(Amut)), Amut)
        b = convert(similar_type(vertices, R, Size(bmut)), bmut)
        return A, b
    end
end

"""
$(SIGNATURES)

$hrep_doc

This function stores its output in the (mutable) matrix `A` and vector `b`.
"""
@inline function hrep!(A::AbstractMatrix, b::AbstractVector, hull::ConvexHull)
    signop = edge_normal_sign_operator(hull)
    vertices = hull.vertices
    n = length(vertices)
    @boundscheck begin
        size(A, 1) >= n || throw(DimensionMismatch())
        size(A, 2) == 2 || throw(DimensionMismatch())
        size(A, 1) == length(b) || throw(DimensionMismatch)
    end
    if length(b) != n
        @inbounds A .= 0
        @inbounds b .= 0
    end
    @inbounds @simd for i = Base.OneTo(n)
        v1 = vertices[i]
        v2 = vertices[ifelse(i == n, 1, i + 1)]
        δ = v2 - v1
        δx, δy = unpack(δ)
        outward_normal = signop(SVector(δy, -δx))
        Ai = transpose(outward_normal)
        bi = Ai * v1
        A[i, 1] = Ai[1]
        A[i, 2] = Ai[2]
        b[i] = bi
    end
    nothing
end
