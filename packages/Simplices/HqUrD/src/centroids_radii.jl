"""
    centroids_radii(points::Array{Float64, 2}, indices_simplices::Array{Int, 1})
Compute the centroids and radii of the simplices in the triangulation in any dimension.

`points::Array{Float64, 2}` Points furnishing the triangulation (size = npoints x dim).
`indices_simplices::Array{Int, 1}` Indices of the vertices furnishing simplices of the
    triangulation. Each row refers to one simplex.
"""
function centroids_radii2(points, indices_simplices)
    dim = size(points, 2)
    nsimplices = size(indices_simplices, 1)
    centroids = zeros(nsimplices, dim)
    radii = zeros(nsimplices)

    for i = 1:nsimplices
        simplex = points[indices_simplices[i, :], :] # (dim + 1) x dim)
        centroid = sum(simplex, dims=1) / (dim + 1)
        centroid_matrix = repeat(centroid, dim + 1, 1)

        # Subtract centroid from each simplex
        subtracted = simplex - centroid_matrix
        radius = sqrt(maximum(sum(subtracted.^2, dims=2)))

        centroids[i, :] = centroid
        radii[i] = radius

    end

    return centroids, radii
end
