"""
    invariantset(embedding, tolerance)

Determine whether an embedding forms an invariant set.
"""
function invariantset(embedding)
    lastpoint = embedding[end, :]
    dim = size(embedding, 2)

    # Triangulate the embedding using all points but the last
    triangulation = delaunayn(embedding[1:end-1, :])

    points = embedding[1:end-1, :]
    simplex_indices = triangulation

    # Centroids and radii of simplices in the triangulation
    centroids, radii = centroids_radii2(points, simplex_indices)

    lastpoint_matrix = repeat(lastpoint', size(centroids, 1), 1)

    # Find simplices that can contain the last point (not all can)
    dists_lastpoint_and_centroids = sum((lastpoint_matrix - centroids).^2, dims=2)
    distdifferences = radii.^2 - dists_lastpoint_and_centroids

    # Find the row indices of the simplices that possibly contain the last point (meaning that
    # dist(simplex_i, lastpoint) <= radius(simplex), so the circumsphere of the simplex
    # contains the last point.
    valid_simplex_indices = find(heaviside0(distdifferences) .* collect(1:size(triangulation[2], 1)))

    n_validsimplices = size(valid_simplex_indices, 1)

    # Loop over valid simplices and check whether the corresponding simplex actually
    # contains the last point.
    i = 1
    lastpoint_contained = false

    # Continue checking if simplices contain the last point until some simplex contains it.
    # Then the point must necessarily be inside the convex hull of the triangulation formed
    # by those simplices.
    while i <= n_validsimplices && !lastpoint_contained
        # Subsample the valid simplex and compute its orientation
        simplex = embedding[simplex_indices[valid_simplex_indices[i], :], :]
        orientation_simplex = det([ones(dim + 1, 1) simplex])

        beta = 1 # Convex expansion coefficient

        j = 1
        while j <= dim + 1 && beta >= 0
            tmp = copy(simplex)
            tmp[j, :] = copy(lastpoint)
            beta = det([ones(dim + 1, 1) tmp]) * sign(orientation_simplex)
            j = j + 1
        end

        # If the last convex expansion coefficient is positive, the last point is contained
        # in the triangulation (because all the previous coefficients must have been nonnegative)
        if beta >= 0
            lastpoint_contained = true
        end

        i = i + 1
    end
    # If the last point is contained in the triangulation, the set is invariant.
    return lastpoint_contained
end
