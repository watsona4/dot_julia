
"""
Compute orientations of simplices given the `points` forming the vertices of the simplices
(a n_vertices x dim array) and `simplex_inds` (a n_simplices x (dim+1) array), telling how
the simplices are formed from the vertices.
"""
function orientations(points::AbstractArray{Float64, 2}, simplex_inds::AbstractArray{Int, 2})
    n_simplices = size(simplex_inds, 1)
    dim = size(simplex_inds, 2) - 1
    orientations = zeros(Float64, n_simplices)

    for i = 1:n_simplices
        orientations[i] = det(hcat(view(points, view(simplex_inds, i, :), :), ones(dim + 1)))
    end

    return orientations
end
