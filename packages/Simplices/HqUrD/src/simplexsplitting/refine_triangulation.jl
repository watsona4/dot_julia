"""
    refine_triangulation(triang_vertices, triang_simplex_indices, split_indices, k)

Refine a triangulation with explicitly providing the splitting rules. In this function,
these are computed internally, using a splitting factor of k.
"""
function refine_triangulation(triang_vertices, triang_simplex_indices, split_indices, k)

    if length(split_indices) == 0
        untouched_indices = collect(1:size(triang_simplex_indices, 1))
        return triang_vertices, triang_simplex_indices, untouched_indices
    end


    # The number of simplices to split
    n_split_simplices = length(split_indices)

    # The dimension of the space
    E = size(triang_vertices, 2)


    # Generic rules for splitting a simplex
    splitting_rules = simplicial_subdivision(k, E)

    # Rules for forming the strictly new vertices of the subtriangulation
    rules = splitting_rules[1]

    # Array where each row represents one of the new simplices in the splitted simplex
    subtriangulation = splitting_rules[2]

    # How many new vertices are created each split?
    n_newvertices_eachsplit = size(rules, 1)

    # We need an array that can accomodate all of them. Each row in this
    # array will be a new vertex. Stacks of n_newvertices_eachsplit * E arrays.
    # We have as many as we have simplices to split.
    new_vertices = zeros(n_newvertices_eachsplit * n_split_simplices, E)

    # Fill the array by looping over all simplices that we want to split
    for i = 1:n_split_simplices
        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_vertices
        ind = n_newvertices_eachsplit * (i -1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Get the vertices of the simplex currently being splitted. Each of the
        # n_newvertices_eachsplit new vertices will be a linear combination
        # of these vertices. Each row is a vertex.
        vertices = triang_vertices[triang_simplex_indices[simplex_idx, :], :]

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

            new_vertices[ind_newvertex, :] = sum(original_vertices, dims=1) ./ k

        end
    end

    # Find the unique new vertices
    new_vertices_noreps = unique(new_vertices, dims=1)
    Ind = Vector{Int}(undef, size(new_vertices, 1))
    for i = 1:size(new_vertices_noreps, 1)
        for j = 1:size(new_vertices, 1)
            if new_vertices_noreps[i, :] == new_vertices[j, :]
                Ind[j] = i
            end
        end
    end

    # Combine old and newly introduced vertices
    num_vertices_beforesplit = size(triang_vertices, 1)
    triang_vertices = vcat(triang_vertices, new_vertices_noreps)

    # Update the Ind array, so that we start at the new vertices
    Ind = Ind .+ num_vertices_beforesplit
    num_simplices_each_split = size(subtriangulation, 1)

    # The subsimplices formed by the splitting. Each row contains E + 1 indices referencing
    # the vertices furnishing that particular subsimplex (now found in the updated
    # triang_vertices array).
    newtriangulation = Array{Float64, 2}(undef, num_simplices_each_split * n_split_simplices, E + 1)

    # For each simplex that we need to split,
    for i = 1:n_split_simplices
        # The beginning of the stack we need to fill.
        index = num_simplices_each_split * (i - 1)

        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_vertices
        ind = n_newvertices_eachsplit * (i -1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Pick the indices of the original vertices. Should be a column vector.
        inds_original_vertices = triang_simplex_indices[simplex_idx, :]

        # Indices of the new vertices. Should be a column vector
        inds_new_vertices = Ind[(ind + 1):(ind + n_newvertices_eachsplit)]
        inds_all_vertices = vcat(inds_original_vertices, inds_new_vertices)

        # Go through each of the subsimplices formed by splitting that simplex
        for j = 1:num_simplices_each_split
            newtriangulation[index + j, :] = inds_all_vertices[subtriangulation[j, :]]
        end
    end

    # Indices of the simplices that are not split
    untouched_indices = setdiff(1:size(triang_simplex_indices, 1), split_indices)


    triang_simplex_indices = round.(Int, vcat(triang_simplex_indices[untouched_indices, :],
                                  newtriangulation))

    return triang_vertices, triang_simplex_indices, untouched_indices
end
