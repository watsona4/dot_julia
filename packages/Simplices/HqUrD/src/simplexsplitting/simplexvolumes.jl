"""
    centroids_radii(points::Array{Float64, 2}, indices_simplices::Array{Int, 1})
Compute the centroids and radii of the simplices in the triangulation in any dimension.

`points::AbstractArray{Float64, 2}` Points furnishing the triangulation (size = npoints x dim).
`indices_simplices::AbstractArray{Int, 1}` Indices of the vertices furnishing simplices of the
    triangulation. Each row refers to one simplex.
"""
function simplex_volumes(points::AbstractArray{Float64, 2},
                            indices_simplices::AbstractArray{Int, 2})
    dim = size(points, 2)
    nsimplices = size(indices_simplices, 1)

    volumes = zeros(Float64, nsimplices)

    for i = 1:nsimplices
        simplex = copy(transpose(points[indices_simplices[i, :], :]))
        volumes[i] = abs(det([ones(1, dim + 1); simplex]))
    end

    return volumes
end
