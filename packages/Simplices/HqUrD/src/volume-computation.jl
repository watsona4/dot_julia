"""
    Computes the volume of a polytope.

# Arguments

`polytope_vertices::AbstractArray{Float64, 2}`    Contains all the intersecting points between all the boundaries of the simplices. Each row represents some intersecting point. Matrix of size D-by-N, where D = total number of intersecting points. Each row is an intersecting point.
`convexp::AbstractArray{Float64, 2}`  Convex expansions of the vertices in `polytope_vertices` in terms of the original simplices. The size of this array is D-by-(2N + 2), where D = total number of intersecting points. (2N + 2) corresponds to the number of vertices in each simplex * 2. The first n+1 columns correspond to the convex expansion coefficients of the intersecting points in terms of the vertices generating simplex 1. The remaining n+1 to (2N+2) columns correspond to the convex expansion coefficients of the intersecting points in terms of the vertices generating simplex 2. The faces of each simplex are numbered according to the column labels.
"""
function VolumeComputation(polytope_vertices::AbstractArray{Float64, 2},
                           convexp::AbstractArray{Float64, 2})

    num_generators = size(polytope_vertices, 1) # The number of polytope generators (vertices)
    dim = size(polytope_vertices, 2)
    intvol = 0.0

    if num_generators == dim + 1 # Intersection is a simplex
        return abs(det(vcat(ones(1, dim + 1), copy(transpose(polytope_vertices)))))
    elseif num_generators > dim + 1 # Intersection is a polytope.
        # The polytope faces and how many of them are nonsingular.
        triangulation_polytope_faces, n_nonsingular_faces = TriangulationPolytopeFaces(convexp, num_generators, dim)

        if n_nonsingular_faces >= dim + 1
            polytope_centroid = ones(1, num_generators) * polytope_vertices / num_generators

            for a = 1:size(triangulation_polytope_faces, 1)
                Ind = round.(Int64, triangulation_polytope_faces[a, :])
                vertices = [polytope_vertices[vec(Ind), :]; polytope_centroid]
                intvol += abs(det([ones(dim + 1, 1) vertices]))
            end
        end
    end
    return intvol
end
