"""
    centroids_radii(points::Array{Float64, 2},
                    indices_simplices::Array{Int, 1})

Compute the centroids and radii of the simplices in the triangulation in any
dimension.

- `points::Array{Float64, 2}` Points furnishing the triangulation
    (size = npoints x dim).
- `indices_simplices::Array{Int, 1}` Indices of the vertices furnishing
    simplices of the triangulation. Each row refers to one simplex.
"""
function centroids_radii2(points, indices_simplices)
    dim = size(points, 2)
    nsimplices = size(indices_simplices, 1)
    centroids = zeros(nsimplices, dim)
    radii = zeros(nsimplices)

    for i = 1:nsimplices
        simplex = points[indices_simplices[i, :], :] # (dim + 1) x dim)
        centroid = sum(simplex, dims = 1) / (dim + 1)
        centroid_matrix = repeat(centroid, dim + 1, 1)

        # Subtract centroid from each simplex
        subtracted = simplex - centroid_matrix
        radius = sqrt(maximum(sum(subtracted.^2, dims = 2)))

        centroids[i, :] = centroid
        radii[i] = radius

    end

    return centroids, radii
end



"""
    centroids_radii(points::Array{Float64, 2},
                    indices_simplices::Array{Int, 1})

Compute the volumes of a set of simplices.

- `points::Array{Float64, 2}` Points furnishing the triangulation
    (size = npoints x dim).
- `indices_simplices::Array{Int, 1}` Indices of the vertices furnishing
    simplices of the triangulation. Each row refers to one simplex.
"""
function simplex_volumes(points::AbstractArray{Float64, 2},
                        indices_simplices::AbstractArray{Int, 2})
    dim = size(points, 2)
    nsimplices = size(indices_simplices, 1)

    volumes = zeros(Float64, nsimplices)

    for i = 1:nsimplices
        simplex = transpose(points[indices_simplices[i, :], :])
        volumes[i] = abs(det([ones(1, dim + 1); simplex]))
    end

    return volumes
end


"""
Compute orientations of simplices given the `points` forming the vertices of
the simplices (a n_vertices x dim array) and `simplex_inds` (a n_simplices x
(dim+1) array), telling how the simplices are formed from the vertices.
"""
function orientations(points::AbstractArray{Float64, 2},
                    simplex_inds::AbstractArray{Int, 2})
    n_simplices = size(simplex_inds, 1)
    dim = size(simplex_inds, 2) - 1
    orientations = Vector{Float64}(undef, n_simplices)

    for i = 1:n_simplices
        orientations[i] = det(hcat(view(points, view(simplex_inds, i, :), :),
                                ones(dim + 1)))
    end

    return orientations
end
