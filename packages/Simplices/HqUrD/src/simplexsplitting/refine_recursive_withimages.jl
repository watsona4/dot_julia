"""
    refine_recursive_images(points, image_points, simplex_inds, maxsize, k)

Refine a triangulation. Consider both simplices and their images.
Continue splitting some fraction of the simplices
with size reduction factor of k until until the maximum simplex size is below
some reference size `refsize` (for example, the maximum simplex size in the
original triangulation).

Returns a tuple containing the refined triangulation and some information about
it, as follows:

(points, image_points, simplex_inds, centroids, centroids_im, radii, radii_im, simplexvolumes, imagevolumes)
"""
function refine_recursive_images(points, image_points, simplex_inds, maxsize, k; niter = 1)
    if niter == 1
        println(size(points, 2), "D triangulation containing ", size(simplex_inds, 1), " simplices.")
        print("Target simplex radius = ", round(maxsize, 4), ". ")
        println("Split simplices into subsimplices with radii reduced by  factor of ", k, ".")
    end

    centroids, radii = centroids_radii2(points, simplex_inds)
    centroids_im, radii_im = centroids_radii2(image_points, simplex_inds)
    # If convergence is reached, return the triangulation and the centroids and radii of
    # the simplices furnishing the triangulation
    maxradius = max(maximum(radii), maximum(radii_im))
    print("Refinement #", niter, "\tMaximum simplex radius = ", floor(maxradius, 4),  ". ")

    if maxradius < maxsize || niter > 100
        if niter > 100
            println("\n\t\tMaximum number of iterations (100) reached. Ending refinement.")
        else
            println("\n\t\tRefinement finished.\n")
        end

        simplexvolumes = simplex_volumes(points, simplex_inds)
        imagevolumes = simplex_volumes(image_points, simplex_inds)
        return points, image_points, simplex_inds, centroids, centroids_im, radii, radii_im,
                simplexvolumes, imagevolumes
    end

    # If no convergence, continue splitting some fraction of the largest simplices.
    if length(radii) == 1
        percentile = 1.0
        split_indices = [1]
    else
        # What portion of the largest simplices to split (1 - percentile)?
        percentile = 0.999
        split_indices = []

        # If the simplices in the triangulation are very regular, there might not be
        # any simplices larger than a given percentile. If so, reduce percentile iteratively
        # until there are simplices larger than the percentile.
        while length(split_indices) == 0
            # Check if all elements are approximately the same size. If so, we must split all
            # of them.
            if all(y-> isapprox(radii[1], y), radii)
                split_indices =  find(radii .> 0)
            elseif all(y-> isapprox(radii[1], y), radii_im)
                split_indices =  find(radii_im .> 0)
            else
                split_indices = find(radii .> quantile(radii, percentile))
                split_indices_im = find(radii_im .> quantile(radii, percentile))
                split_indices = unique([split_indices; split_indices_im])

            end
            percentile = percentile - 0.01
        end
    end

    # The number of simplices to split
    n_split_simplices = length(split_indices)

    # The dimension of the space
    E = size(points, 2)

    # Generic rules for splitting a simplex
    splitting_rules = simplicial_subdivision(k, E)

    # Rules for forming the strictly new vertices of the subtriangulation
    rules = splitting_rules[1]

    # Array where each row represents one of the new simplices in the splitted simplex
    subtriangulation = splitting_rules[2]

    # How many new vertices are created each split?
    n_newvertices_eachsplit = size(rules, 1)

    println(" Splitting ", n_split_simplices, "/", size(simplex_inds, 1), " (", @sprintf("%.4f", 1.0 - percentile), " %)", " simplices and their corresponding images into ", n_split_simplices * n_newvertices_eachsplit - 1, " subsimplices.")


    # We need an array that can accomodate all of them. Each row in this
    # array will be a new vertex. Stacks of n_newvertices_eachsplit * E arrays.
    # We have as many as we have simplices to split.
    new_points = zeros(n_newvertices_eachsplit * n_split_simplices, E)
    new_imagepoints = zeros(n_newvertices_eachsplit * n_split_simplices, E)

    # Fill the array by looping over all simplices that we want to split
    for i = 1:n_split_simplices
        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_points
        ind = n_newvertices_eachsplit * (i - 1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Get the vertices of the simplex currently being splitted. Each of the
        # n_newvertices_eachsplit new vertices will be a linear combination
        # of these vertices. Each row is a vertex.
        vertices = points[simplex_inds[simplex_idx, :], :]
        imagevertices = image_points[simplex_inds[simplex_idx, :], :]

        # Generate the strictly new vertices for each sub
        for j = 1:n_newvertices_eachsplit
            # The index for a particular new vertex of the ith new simplex
            ind_newvertex = ind + j

            # Compute the jth vertex of the subtriangulation of the ith simplex

            # Go the jth new subsimplex of the ith splitted simplex. The entries of this
            # vector
            jth_subsimplex = rules[j, :]

            # Pick the corresponding original vertices with indices contained in rules[j, :]
            original_vertices = vertices[rules[j, :], :]
            original_vertices_image = imagevertices[rules[j, :], :]

            new_points[ind_newvertex, :] = sum(original_vertices, dims=1) ./ k
            new_imagepoints[ind_newvertex, :] = sum(original_vertices_image, dims=1) ./ k

        end
    end

    # Find the unique new vertices
    new_points_noreps = unique(new_points, 1)
    new_imagepoints_noreps = Array{Float64}(size(new_points_noreps, 1), E)

    Ind = Vector{Int}(size(new_points, 1))
    for i = 1:size(new_points_noreps, 1)

        count = 0

        for j = 1:size(new_points, 1) # run over the possibly repeated vertices
            if new_points_noreps[i, :] == new_points[j, :]
                Ind[j] = i

                count = count + 1
                if count == 1
                    new_imagepoints_noreps[i, :] = new_imagepoints[j, :]
                end
            end
        end
    end

    # TEST:  assert all zeros.
    #@show unique(new_imagepoints, 1) - new_imagepoints_noreps

    # Combine old and newly introduced vertices
    num_vertices_beforesplit = size(points, 1)
    points = vcat(points, new_points_noreps)
    image_points = vcat(image_points, new_imagepoints_noreps)

    # Update the Ind array, so that we start at the new vertices
    Ind = Ind + num_vertices_beforesplit
    num_simplices_each_split = size(subtriangulation, 1)

    # The subsimplices formed by the splitting. Each row contains E + 1 indices referencing
    # the vertices furnishing that particular subsimplex (now found in the updated
    # points array).
    newtriangulation = Array{Float64}(num_simplices_each_split * n_split_simplices, E + 1)

    # For each simplex that we need to split,
    for i = 1:n_split_simplices
        # The beginning of the stack we need to fill.
        index = num_simplices_each_split * (i - 1)

        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_points
        ind = n_newvertices_eachsplit * (i - 1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Pick the indices of the original vertices. Should be a column vector.
        inds_original_vertices = simplex_inds[simplex_idx, :]

        # Indices of the new vertices. Should be a column vector
        inds_new_points = Ind[(ind + 1):(ind + n_newvertices_eachsplit)]
        inds_all_vertices = vcat(inds_original_vertices, inds_new_points)

        # Go through each of the subsimplices formed by splitting that simplex
        for j = 1:num_simplices_each_split
            newtriangulation[index + j, :] = inds_all_vertices[subtriangulation[j, :]]
        end
    end

    # Indices of the simplices that are not split
    untouched_indices = complementary(split_indices, size(simplex_inds, 1))

    simplex_inds = round.(Int, vcat(simplex_inds[untouched_indices, :],
                                  newtriangulation))


    refine_recursive_images(points, image_points, simplex_inds, maxsize, k; niter = niter + 1)
end
