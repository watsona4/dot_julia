"""
$(SIGNATURES)

Find the closest point to `p` within `hull`. If `p` is inside `hull`,
`p` itself is returned.
"""
function closest_point(p::PointLike, hull::ConvexHull)
    op = orientation_comparator(hull)
    vertices = hull.vertices
    n = length(vertices)
    @inbounds begin
        if n === 0
            throw(ArgumentError())
        elseif n === 1
            return vertices[1]
        else
            closest = p
            i = 1
            v1 = vertices[n]
            v2 = vertices[1]
            while true
                δ = v2 - v1
                p′ = p - v1
                strictly_outside_edge = op(cross2(p′, δ), 0)
                if strictly_outside_edge
                    # Find closest point to current edge.
                    λ = clamp(p′ ⋅ δ / (δ ⋅ δ), false, true)
                    closest_to_edge = v1 + λ * δ

                    # Accept if previous candidate was p itself or if it's closer.
                    if closest == p || normsquared(closest_to_edge - p) < normsquared(closest - p)
                        closest = closest_to_edge
                    end
                end
                i == n && break
                v1 = vertices[i]
                v2 = vertices[i + 1]
                i += 1
            end
            return closest
        end
    end
end
