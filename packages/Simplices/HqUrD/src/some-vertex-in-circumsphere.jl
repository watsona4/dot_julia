"""
    SomeVertexInCircumsphere(simplex1, r2, c2)

Decides whether some vertices of simplex1 lies inside the circumsphere of simplex2
(defined by the radius and centroid of simplex1, r2 and c2). Each column of simplex1 is a vertex.

Arguments
---------
c2::Vector{Float64} Column vector. Centroid of simplex2.
r2::Float64 Radius of simplex 2

Returns either 0 or 1; 1 if some of the vertices of simplex1 are contained in the circumsphere
of simplex 2, 0 otherwise.
"""
function SomeVertexInCircumsphere(simplex1, r2, c2)
    # The dimension
    n = size(simplex1, 1)

    i = 1
    some_vertex_in_circumsphere = false

    while i <= (n + 1) && !some_vertex_in_circumsphere
        # Difference between the i-th vertex of simplex1 and centroid of simplex2
        ith_vertex = simplex1[:, i] - c2
        tmp = heaviside0(r2^2 - transpose(ith_vertex) * ith_vertex) # Radius times norm

        if tmp == 1
            some_vertex_in_circumsphere = true
        end

        i = i + 1
    end

    return some_vertex_in_circumsphere
end
