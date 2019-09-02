"""
$(SIGNATURES)

Compute the centroid or geometric center of the given `ConvexHull` using the
formulas given [here](https://en.wikipedia.org/wiki/Centroid#Of_a_polygon).
"""
function centroid(hull::ConvexHull)
    T = eltype(hull)
    R = arithmetic_closure(T)
    vertices = hull.vertices
    n = length(vertices)
    @inbounds begin
        if n === 0
            error()
        elseif n === 1
            return R.(vertices[1])
        elseif n === 2
            return (vertices[1] + vertices[2]) / 2
        else
            c = cross2(vertices[n], vertices[1])
            centroid = (vertices[n] + vertices[1]) * c
            double_area = c
            @simd for i in Base.OneTo(n - 1)
                c = cross2(vertices[i], vertices[i + 1])
                centroid += (vertices[i] + vertices[i + 1]) * c
                double_area += c
            end
            double_area = abs(double_area)
            centroid /= 3 * double_area
            return centroid
        end
    end
end
