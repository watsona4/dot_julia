"""
    SplitInfo(inds_toolarge::Vector{Int}, ks::Vector{Int})

Stores information about a potential splitting of a triangulation.
"""
type SplitInfo
    # Indices of the simplices that are too large
    inds_toolarge::Vector{Int}

    # The corresponding splitting factors needed to reduce the radii of the simplices
    # in `inds_toolarge` to below the desired target radius
    ks::Vector{Int}
end


"""
    get_split_info(t::Triangulation,
                target_radius::Float64)

Given a `Triangulation`, returns the indices of simplices of the triangulation that must be
split in order for the maximum simplex radius to be below a `target_radius`.

The corresponding splitting factors are also returned.
"""
function get_split_info(t::Triangulation,
                        target_radius::Float64)

    # Find the radii and centroids of the simplices we want to split
    centroids, radii = centroids_radii2(t.points, t.simplex_inds)
    centroids_im, radii_im = centroids_radii2(t.impoints, t.simplex_inds)
    dim = size(centroids, 2)
    # For each simplex-imagesimplex pair, determine if either of them has a radius
    # larger than the allowed `target_radius`. Simultaneously, calculate the necessary
    # splitting factors k needed to reduce their radius to below `target_radius`
    inds_toolarge = Int[]
    ks = Int[]
    resulting_radii = Float64[] # store the resulting radii for after splitting
    n_new_simplices = 0

    # Indices of the simplices that are not split
    untouched_indices = setdiff(1:size(t.simplex_inds, 1), inds_toolarge)

    for i = 1:length(radii)
        if radii[i] >= target_radius || radii_im[i] >= target_radius
            largest_radius = max(radii[i], radii_im[i])
            k = find_k(largest_radius, target_radius)
            n_new_simplices += k^dim
            append!(resulting_radii, largest_radius/k)
            append!(ks, k)
            append!(inds_toolarge, i)
        end
    end

    # Sort indices of the simplices that are too large so that they appear in the
    # order of `sort_inds` sorted in decreasing order.
    # This way, the number of subsimplices and subvertices
    # generated for each parent simplex is regular, so we can do a simple loop to keep
    # track of the indices of the new vertices and simplices generated.
    inds_toolarge = inds_toolarge[sortperm(ks, rev = true)]
    ks = sort!(ks, rev = true) # actually sort k too

    return SplitInfo(inds_toolarge, ks)
end
