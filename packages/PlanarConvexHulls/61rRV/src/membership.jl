"""
$(SIGNATURES)

Return whether `point` is in `hull`.
"""
function Base.in(point::PointLike, hull::ConvexHull)
    op = orientation_comparator(hull)
    vertices = hull.vertices
    n = length(vertices)
    @inbounds begin
        if n === 0
            return false
        elseif n === 1
            return point == hull.vertices[1]
        elseif n === 2
            p′ = point - vertices[1]
            δ = vertices[2] - vertices[1]
            cross2(p′, δ) == 0 && 0 <= p′ ⋅ δ <= δ ⋅ δ
        else
            δ = vertices[1] - vertices[n]
            for i in Base.OneTo(n - 1)
                op(cross2(point - vertices[i], δ), 0) && return false
                δ = vertices[i + 1] - vertices[i]
            end
            return !op(cross2(point - vertices[n], δ), 0)
        end
    end
end
