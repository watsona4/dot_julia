
"""
Contains the results of
"""
struct RefinementQuery
    # The points (vertices) in the original simplex space
    points::AbstractArray{Float64, 2}

    # The points (vertices) in the image simplex space
    impoints::AbstractArray{Float64, 2}

    # Indices corresponding to the simplices of the triangulation. The indices in a single
    # row of this matrix indicates from which rows of `points` and `impoints` the
    # corresponding simplices should be constructed.
    simplex_inds::AbstractArray{Int64, 2}

    # The maximal allowed radius in the resulting triangulation  splitting simplices
    # that are too big.
    target_radius::Float64

    # The number of new simplices created by splitting to the desired `target_radius`
    n_new_simplices::Int

    ks::AbstractVector{Int}

    # Indices of the simplices that will be split
    inds_toolarge::AbstractVector{Int}

    # The resulting maximum subsimplex radius for each simplex simplex that is being
    # split due to being larger than the allowed target size. Should contain
    # max(radius(simplex), radius(image simplex)).
    resulting_radii::AbstractVector{Float64}

    # The indices of the simplices that will not be split
    inds_untouched::AbstractVector{Int}
end


"""
   query_refinement(t::Triangulation, target_radius::Float64)

Calculates information about the triangulation resulting from calling `refine_variable_k`
with identical arguments.

`refine_variable_k` works as follows:

Refines a triangulation so that the maximum simplex radius is less than `target_radius`.

The splitting is done in a single iteration. For each simplex that we want to split (given
by the integer vector `inds_to_split`, referencing rows of the `simplex_inds` array),
we indentify the necessary splitting factor `k`

Each row in the integer array `simplex_inds` represents a simplex in both the original
space and in the image space. The E+1 elements of each row vector in `simplex_inds`
references a set of corresponding rows in `points` and `impoints`, such that

points[simplex_inds[k, :], :] gives the k-th simplex in the original space, and
impoints[simplex_inds[k, :], :] gives the k-th simplex in the image space.
"""
function query_refinement(t::Triangulation,
                        target_radius::Float64)
   dim = size(t.points, 2)
   # For each simplex-imagesimplex pair, determine if either of them has a radius
   # larger than the allowed `target_radius`. Simultaneously, calculate the necessary
   # splitting factors k needed to reduce their radius to below `target_radius`
   inds_toolarge = Int[]
   ks = Int[]
   resulting_radii = Float64[] # store the resulting radii for  splitting
   n_new_simplices = 0

   # Indices of the simplices that are not split
   untouched_indices = setdiff(1:size(t.simplex_inds, 1), inds_toolarge)

   for i = 1:length(t.radii)
      if t.radii[i] >= target_radius || t.radii_im[i] >= target_radius
         largest_radius = max(t.radii[i], t.radii_im[i])
         k = find_k(largest_radius, target_radius)
         n_new_simplices += k^dim
         append!(resulting_radii, largest_radius/k)
         append!(ks, k)
         append!(inds_toolarge, i)
      end
   end

   # Indices of the simplices that are not split
   untouched_indices = setdiff(1:size(t.simplex_inds, 1), inds_toolarge)


   return RefinementQuery(t.points, t.impoints, t.simplex_inds, target_radius,
                           n_new_simplices, ks, inds_toolarge, resulting_radii,
                           untouched_indices)
end

"""
    find_k(radius::Float64, target_radius::Float64)

Finds the splitting factor `k` needed to split a simplex with a given `radius` into
subsimplices each having radii less than `target_radius`.
"""
function find_k(radius::Float64, target_radius::Float64; tol = 0.0001)
    ceil(Int, radius/(target_radius - tol))
end

"""
    SplitInfo(inds_toolarge::Vector{Int}, ks::Vector{Int})

Stores information about a potential splitting of a triangulation.
"""
struct SplitInfo
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
    dim = size(t.points, 2)
    # For each simplex-imagesimplex pair, determine if either of them has a radius
    # larger than the allowed `target_radius`. Simultaneously, calculate the necessary
    # splitting factors k needed to reduce their radius to below `target_radius`
    inds_toolarge = Int[]
    ks = Int[]
    resulting_radii = Float64[] # store the resulting radii for  splitting
    n_new_simplices = 0

    for i = 1:length(t.radii)
        if t.radii[i] >= target_radius || t.radii_im[i] >= target_radius
            largest_radius = max(t.radii[i], t.radii_im[i])
            k = find_k(largest_radius, target_radius)
            n_new_simplices += k^dim
            append!(resulting_radii, largest_radius/k)
            append!(ks, k)
            append!(inds_toolarge, i)
        end
    end

   return SplitInfo(inds_toolarge, ks)
end

"""
    SplitRules(SplitInfo)

Stores the simplex splitting rules (a result of a `simplicial_subdivision(dim, k)` call)
for a given dimension and splitting factor.
"""
struct SplitRules
    rules::AbstractArray{Int, 2}
    indices::AbstractArray{Int, 2}
end


"""
Refines a triangulation `t`using shape-preserving simplex subdivision. Uses
a variable splitting factor, so that all simplices' radii are rendered less
than `target_radius`. Operates in-place on `t`.
"""
function refine_variable_k!(t::Triangulation, target_radius::Float64)
   #=
   # Get:
   # (1) The indices of simplices that must be split in order for all the radii
   #     of the provided simplices to be below a `target_radius`.
   # (2) The corresponding splitting factors (`ks`).
   =#
   split_info = get_split_info(t, target_radius)
   query = query_refinement(t, target_radius)
   @assert split_info.ks == query.ks

   # If any simplices does not need splitting, keep track of their indices
   n_simplices = size(t.simplex_inds, 1)
   untouched_inds = setdiff(1:n_simplices, split_info.inds_toolarge)

   if length(untouched_inds) > 0
       simplex_inds = vcat(t.simplex_inds, t.simplex_inds[untouched_inds, :])
   end

   # Loop over splitting factors
   for i in 1:length(unique(split_info.ks))
      #=
      # Split all simplices that needs to be split with this splitting factor
      # in order to reduce their radius to below `target_radius`
      =#
      k = unique(split_info.ks)[i]
      split_inds = split_info.inds_toolarge[find(split_info.ks .== k)]

      if length(split_inds) > 0
         refine_t!(t, split_inds, k)
      else
         warn("Target radius $target_radius is too large. All simplex radii are
               already smaller than this.")
      end
   end
end


"""
Refines a triangulation `t`using shape-preserving simplex subdivision. Uses
a variable splitting factor, so that all simplices' radii are rendered less
than `target_radius`.
"""
function refine_variable_k(t::Triangulation, target_radius::Float64)
   #=
   # Get:
   # (1) The indices of simplices that must be split in order for all the radii
   #     of the provided simplices to be below a `target_radius`.
   # (2) The corresponding splitting factors (`ks`).
   =#
   split_info = get_split_info(t, target_radius)
   query = query_refinement(t, target_radius)
   @assert split_info.ks == query.ks

   # If any simplices does not need splitting, keep track of their indices
   dim = size(t.points, 2)
   n_simplices = size(t.simplex_inds, 1)
   untouched_inds = setdiff(1:n_simplices, split_info.inds_toolarge)

   if length(untouched_inds) > 0
       simplex_inds = vcat(t.simplex_inds, t.simplex_inds[untouched_inds, :])
   end

   # Loop over splitting factors
   for i in 1:length(unique(split_info.ks))
      #=
      # Split all simplices that needs to be split with this splitting factor
      # in order to reduce their radius to below `target_radius`
      =#
      k = unique(split_info.ks)[i]
      split_inds = split_info.inds_toolarge[find(split_info.ks .== k)]

      if length(split_inds) > 0
         refine_t!(t, split_inds, k)
      else
         warn("Target radius $target_radius is too large. All simplex radii are
               already smaller than this.")
      end
   end
end
