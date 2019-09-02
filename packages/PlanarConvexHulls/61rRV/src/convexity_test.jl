"""
$(SIGNATURES)

Return whether `vertices` are ordered according to vertex order type `O` (a subtype of [`VertexOrder`](@ref)),
and as a result *strongly* convex (see e.g. [CGAL documentation](https://doc.cgal.org/latest/Convex_hull_2/index.html)
for a definition of strong convexity).
"""
function is_ordered_and_strongly_convex(vertices::AbstractVector{<:PointLike}, order::Type{O}) where {O<:VertexOrder}
    op = orientation_comparator(O)
    n = length(vertices)
    n <= 2 && return true
    @inbounds begin
        δprev = vertices[n] - vertices[n - 1]
        δnext = vertices[1] - vertices[n]
        for i in Base.OneTo(n - 1)
            op(cross2(δprev, δnext), 0) || return false
            δprev = δnext
            δnext = vertices[i + 1] - vertices[i]
        end
        return op(cross2(δprev, δnext), 0)
    end
end
