
"""
    refine_t!(t::Triangulation, split_indices = [], k)

Refine a triangulation, also updating the images of the simplices
in the triangulation.

`t.points::Array{Float64, 2} is a (n_triangulation_vertices x embeddingdim) sized
    array where each row is a vertex of the triangulation.
`t.simplex_inds::Array{Int, 2}` is an array of size
    (n_trinagulation_simplices x (embeddingdim+1)). Each row of simplex_indices contains
    the indices of the vertices (rows of the vertices array) furnishing the corresponding
    simplex.
`t.impoints::Array{Float64, 2} is a (n_triangulation_vertices x embeddingdim) sized
        array where each row is a vertex of the triangulation.
`split_indices::Array{Int, 1}` are the row numbers of simplex_indices indicating which
    simplices should be split.
"""
function refine_t!(t::Triangulation, split_indices::Vector{Int}, k::Int)

    # The number of simplices to split
    n_split_simplices = length(split_indices)
    n_points_beforesplit = size(t.points, 1)
    # Indices of the simplices that are not split
    untouched_inds = complementary(split_indices, size(t.simplex_inds, 1))

    # The dimension of the space
    E = size(t.points, 2)

    # Rules for forming the strictly new vertices of the subtriangulation
    rules, subtriangulation = simplicial_subdivision(k, E)

    # How many new vertices are created each split?
    nverts_persplit = size(rules, 1)

    # We need an array that can accomodate all of them. Each row in this
    # array will be a new vertex. Stacks of nverts_persplit * E arrays.
    # We have as many as we have simplices to split.
    new_vertices = zeros(nverts_persplit * n_split_simplices, E)
    new_imagevertices = zeros(nverts_persplit * n_split_simplices, E)

    # Fill the array by looping over all simplices that we want to split
    for i = 1:n_split_simplices
        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_vertices
        ind = nverts_persplit * (i -1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Get the vertices of the simplex currently being splitted. Each of the
        # nverts_persplit new vertices will be a linear combination
        # of these vertices. Each row is a vertex.
        vertices = t.points[t.simplex_inds[simplex_idx, :], :]
        imagevertices = t.impoints[t.simplex_inds[simplex_idx, :], :]

        # Generate the strictly new vertices for each sub
        for j = 1:nverts_persplit
            # The index for a particular new vertex of the ith new simplex
            ind_newvertex = ind + j
            # Go the jth new subsimplex of the ith splitted simplex. The entries of this
            # vector
            jth_subsimplex = rules[j, :]

            # Pick the corresponding original vertices with indices contained in rules[j, :]
            original_vertices = vertices[rules[j, :], :]
            original_vertices_image = imagevertices[rules[j, :], :]

            new_vertices[ind_newvertex, :] = sum(original_vertices, dims=1) ./ k
            new_imagevertices[ind_newvertex, :] = sum(original_vertices_image, dims=1) ./ k

        end
    end

    # Find the unique new vertices
    unique_newverts = unique(new_vertices, 1)
    unique_newimverts = Array{Float64}(size(unique_newverts, 1), E)

    Ind = Vector{Int}(size(new_vertices, 1))
    for i = 1:size(unique_newverts, 1)

        count = 0

        for j = 1:size(new_vertices, 1) # run over the possibly repeated vertices
            if unique_newverts[i, :] == new_vertices[j, :]
                Ind[j] = i

                count = count + 1
                if count == 1
                    unique_newimverts[i, :] = new_imagevertices[j, :]
                end
            end
        end
    end
    #@show unique(new_imagevertices, 1) - unique_newimverts
    #@show size(unique(new_imagevertices)), size(unique_newimverts)
    #assert(all(unique(new_imagevertices, 1) - unique_newimverts .≈ 0.0))


    # Start counting indices from the new vertices.
    Ind = Ind + n_points_beforesplit
    nsimplices_persplit = size(subtriangulation, 1)

    # The subsimplices formed by the splitting. Each row contains E + 1 indices referencing
    # the vertices furnishing that particular subsimplex (now found in the updated
    # t.points array).
    subtriangs_inds = Array{Int64}(nsimplices_persplit * n_split_simplices, E + 1)

    # For each simplex that we need to split,
    for i = 1:n_split_simplices
        # The beginning of the stack we need to fill.
        index = nsimplices_persplit * (i - 1)

        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_vertices
        ind = nverts_persplit * (i - 1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Pick the indices of the original vertices. Should be a column vector.
        inds_original_vertices = t.simplex_inds[simplex_idx, :]

        # Indices of the new vertices. Should be a column vector
        inds_newverts = Ind[(ind + 1):(ind + nverts_persplit)]
        inds_allverts = vcat(inds_original_vertices, inds_newverts)

        # Go through each of the subsimplices formed by splitting that simplex
        for j = 1:nsimplices_persplit
            subtriangs_inds[index + j, :] = inds_allverts[subtriangulation[j, :]]
        end
    end

    # Append new values
    t.points = vcat(t.points, unique_newverts)
    t.impoints = vcat(t.impoints, unique_newimverts)
    t.simplex_inds = vcat(t.simplex_inds[untouched_inds , :], subtriangs_inds)

    # Calculate centroids, radii and volumes for the new simplices
    t.centroids, t.radii = centroids_radii2(t.points, t.simplex_inds)
    t.centroids_im, t.radii_im = centroids_radii2(t.impoints, t.simplex_inds)

    @assert length(t.radii) == size(t.simplex_inds, 1)
    @assert size(t.centroids, 1) == size(t.simplex_inds, 1)

    t.volumes = simplex_volumes(t.points, t.simplex_inds)
    t.volumes_im = simplex_volumes(t.impoints, t.simplex_inds)


end


"""
    refine_t!(t::Triangulation, split_indices = [], k)

Refine a triangulation, also updating the images of the simplices
in the triangulation.

`t.points::Array{Float64, 2} is a (n_triangulation_vertices x embeddingdim) sized
    array where each row is a vertex of the triangulation.
`t.simplex_inds::Array{Int, 2}` is an array of size
    (n_trinagulation_simplices x (embeddingdim+1)). Each row of simplex_indices contains
    the indices of the vertices (rows of the vertices array) furnishing the corresponding
    simplex.
`t.impoints::Array{Float64, 2} is a (n_triangulation_vertices x embeddingdim) sized
        array where each row is a vertex of the triangulation.
`split_indices::Array{Int, 1}` are the row numbers of simplex_indices indicating which
    simplices should be split.
"""
function refine_t(t::Triangulation, split_indices::Vector{Int}, k::Int)

    # The number of simplices to split
    n_split_simplices = length(split_indices)
    n_points_beforesplit = size(t.points, 1)
    # Indices of the simplices that are not split
    untouched_inds = complementary(split_indices, size(t.simplex_inds, 1))

    # The dimension of the space
    E = size(t.points, 2)

    # Rules for forming the strictly new vertices of the subtriangulation
    rules, subtriangulation = simplicial_subdivision(k, E)

    # How many new vertices are created each split?
    nverts_persplit = size(rules, 1)

    # We need an array that can accomodate all of them. Each row in this
    # array will be a new vertex. Stacks of nverts_persplit * E arrays.
    # We have as many as we have simplices to split.
    new_vertices = zeros(nverts_persplit * n_split_simplices, E)
    new_imagevertices = zeros(nverts_persplit * n_split_simplices, E)

    # Fill the array by looping over all simplices that we want to split
    for i = 1:n_split_simplices
        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_vertices
        ind = nverts_persplit * (i - 1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Get the vertices of the simplex currently being splitted. Each of the
        # nverts_persplit new vertices will be a linear combination
        # of these vertices. Each row is a vertex.
        vertices = t.points[t.simplex_inds[simplex_idx, :], :]
        imagevertices = t.impoints[t.simplex_inds[simplex_idx, :], :]

        # Generate the strictly new vertices for each sub
        for j = 1:nverts_persplit
            # The index for a particular new vertex of the ith new simplex
            ind_newvertex = ind + j
            # Go the jth new subsimplex of the ith splitted simplex. The entries of this
            # vector
            jth_subsimplex = rules[j, :]

            # Pick the corresponding original vertices with indices contained in rules[j, :]
            original_vertices = vertices[rules[j, :], :]
            original_vertices_image = imagevertices[rules[j, :], :]

            new_vertices[ind_newvertex, :] = sum(original_vertices, dims=1) ./ k
            new_imagevertices[ind_newvertex, :] = sum(original_vertices_image, dims=1) ./ k

        end
    end

    # Find the unique new vertices
    unique_newverts = unique(new_vertices, 1)
    unique_newimverts = Array{Float64}(size(unique_newverts, 1), E)

    Ind = Vector{Int}(size(new_vertices, 1))
    for i = 1:size(unique_newverts, 1)

        count = 0

        for j = 1:size(new_vertices, 1) # run over the possibly repeated vertices
            if unique_newverts[i, :] == new_vertices[j, :]
                Ind[j] = i

                count = count + 1
                if count == 1
                    unique_newimverts[i, :] = new_imagevertices[j, :]
                end
            end
        end
    end
    #@show unique(new_imagevertices, 1) - unique_newimverts
    #@show size(unique(new_imagevertices)), size(unique_newimverts)
    #assert(all(unique(new_imagevertices, 1) - unique_newimverts .≈ 0.0))


    # Start counting indices from the new vertices.
    Ind = Ind + n_points_beforesplit
    nsimplices_persplit = size(subtriangulation, 1)

    # The subsimplices formed by the splitting. Each row contains E + 1 indices referencing
    # the vertices furnishing that particular subsimplex (now found in the updated
    # t.points array).
    subtriangs_inds = Array{Int64}(nsimplices_persplit * n_split_simplices, E + 1)

    # For each simplex that we need to split,
    for i = 1:n_split_simplices
        # Identify the beginning index of the stack we need to fill.
        index = nsimplices_persplit * (i - 1)

        # Figure out what the row indices corresponding to the ith simplex
        # must be. Marks the beginning of each of the simplex stacks in new_vertices
        ind = nverts_persplit * (i - 1)

        # Index of the simplex we need to split
        simplex_idx = split_indices[i]

        # Pick the indices of the original vertices. Should be a column vector.
        inds_original_vertices = t.simplex_inds[simplex_idx, :]

        # Indices of the new vertices. Should be a column vector
        inds_newverts = Ind[(ind + 1):(ind + nverts_persplit)]
        inds_allverts = vcat(inds_original_vertices, inds_newverts)

        # Go through each of the subsimplices formed by splitting that simplex
        for j = 1:nsimplices_persplit
            subtriangs_inds[index + j, :] = inds_allverts[subtriangulation[j, :]]
        end
    end

    # Append new values
    t.points = vcat(t.points, unique_newverts)
    t.impoints = vcat(t.impoints, unique_newimverts)
    t.simplex_inds = vcat(t.simplex_inds[untouched_inds , :], subtriangs_inds)

    # Calculate centroids, radii and volumes for the new simplices
    t.centroids, t.radii = centroids_radii2(t.points, t.simplex_inds)
    t.centroids_im, t.radii_im = centroids_radii2(t.impoints, t.simplex_inds)

    @assert length(t.radii) == size(t.simplex_inds, 1)
    @assert size(t.centroids, 1) == size(t.simplex_inds, 1)

    t.volumes = simplex_volumes(t.points, t.simplex_inds)
    t.volumes_im = simplex_volumes(t.impoints, t.simplex_inds)


end
