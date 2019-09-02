"""
$(SIGNATURES)

Compute the convex hull of `points` and store the result in `hull` using the
[Jarvis march (gift wrapping) algorithm](https://en.wikipedia.org/wiki/Gift_wrapping_algorithm).
This algorithm has ``O(nh)`` complexity, where ``n`` is the number of points and ``h`` is
the number of vertices of the convex hull.
"""
function jarvis_march!(hull::ConvexHull, points::AbstractVector{<:PointLike}; atol=eps(eltype(hull)))
    # Adapted from https://www.algorithm-archive.org/contents/jarvis_march/jarvis_march.html.
    op = orientation_comparator(hull)
    n = length(points)
    vertices = hull.vertices
    @inbounds begin
        # Preallocate
        resize!(vertices, n)
        if n <= 2
            vertices .= points
        else
            # Find an initial hull vertex using lexicographic ordering.
            current = first(points)
            for i in 2 : n
                p = points[i]
                if Tuple(p) < Tuple(current)
                    current = p
                end
            end

            i = 1
            while true
                # Add point
                vertices[i] = current

                # Next point is the one with extremal internal angle.
                next = first(points)
                δnext = next - current
                for j in 2 : n
                    p = points[j]
                    δ = p - current
                    c = cross2(δnext, δ)

                    # Note the last clause here, which ensures strong convexity in the presence of
                    # collinear points by accepting `p` if it's farther away from `current` than
                    # `next`.
                    if next == current || (op(0, c) && abs(c) > atol) || (abs(c) <= atol && δ ⋅ δ > δnext ⋅ δnext)
                        next = p
                        δnext = δ
                    end
                end
                current = next
                current == first(vertices) && break
                i += 1
                if i > n
                    # println(IOContext(stdout, :compact=>false), points)
                    # println(IOContext(stdout, :compact=>false), vertices)
                    error("should never get here.")
                end
            end

            # Shrink to computed number of vertices.
            resize!(vertices, i)
        end
    end
    return hull
end
