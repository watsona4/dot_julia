using Simplices.SimplexSplitting

function canonical_simplex_triangulation(; dim::Int = 3, split_factor::Int = 3)
    # Define vertices of canonical simplex
    canonical_simplex_vertices = zeros(dim + 1, dim)
    canonical_simplex_vertices[2:(dim+1), :] = Matrix(1.0I, dim, dim)
    simplex_indices = zeros(Int, 1, dim + 1)
    simplex_indices[1, :] = collect(1:dim+1)

    refined = refine_triangulation(
        canonical_simplex_vertices,
        simplex_indices, [1],
        split_factor)

    points, simplex_inds = refined[1], refined[2]
    centroids, radii = Simplices.SimplexSplitting.centroids_radii2(points, simplex_inds)
    orientations = Simplices.SimplexSplitting.orientations(points, simplex_inds)
    volumes = abs.(orientations)

    Triangulation(
        points = points,
        simplex_inds = simplex_inds,
        centroids = centroids,
        radii = radii,
        orientations = orientations,
        volumes = volumes
    )
end

@testset "Evenly spaced subsampling" begin
    # Construct a traingulation in which centroids have been computed from the actual
    # subsimplices
    dim = 3
    split_factor = 3
    t = canonical_simplex_triangulation(dim = dim, split_factor = split_factor)

    # Construct the centroids using the algebraic subsampling function
    canonical_simplex = zeros(dim + 1, dim)
    canonical_simplex[2:(dim + 1), :] = Matrix(1.0I, dim, dim)

    algebraic_centroids = evenly_sample(canonical_simplex, split_factor)

    @test (maximum(abs.(t.centroids - algebraic_centroids)) - 0.0) < 1/10^10
end
