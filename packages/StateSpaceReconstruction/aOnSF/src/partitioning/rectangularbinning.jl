
"""
    minima_and_stepsizes(points, ϵ) -> (Vector{Float}, Vector{Float})

Find the minima along each axis of the embedding, and computes appropriate
`stepsizes` given `ϵ`, which provide instructions on how to grid the space.
Assumes each point is a column vector.

Specifically, the binning procedure is controlled by the type of `ϵ`:

1. `ϵ::Int` divides each axis into `ϵ` intervals of the same size.
2. `ϵ::Float` divides each axis into intervals of size `ϵ`.
3. `ϵ::Vector{Int}` divides the i-th axis into `ϵᵢ` intervals of the same size.
4. `ϵ::Vector{Float64}` divides the i-th axis into intervals of size `ϵᵢ`.
"""
function minima_and_stepsizes(points, ϵ)
    if size(points, 1) > size(points, 2)
        error("The dimension of the dataset exceeds the number of points.")
    end
    D = size(points, 1)
    n_pts = size(points, 2)

    axisminima = Vector{Float64}(undef, D)
    top = Vector{Float64}(undef, D)

    for i = 1:D
        axisminima[i] = minimum(points[i, :])
        top[i] = maximum(points[i, :])
    end
    axisminima = axisminima - (top - axisminima) / 100
    top = top + (top - axisminima) / 100

    stepsizes = Vector{Float64}(undef, D)
    if typeof(ϵ) <: Float64
        stepsizes = [ϵ for i in 1:D]
    elseif typeof(ϵ) == Vector{Float64}
        stepsizes = ϵ
    elseif typeof(ϵ) <: Int
        stepsizes = (top - axisminima) / ϵ
    elseif typeof(ϵ) == Vector{Int}
        stepsizes = (top - axisminima) ./ ϵ
    end

    axisminima, stepsizes
end

"""
    assign_integer_bin_label_to_eachpoint!(
        A::Array{Int, 2},
        embedding_points::Array{Float64, 2},
        axisminima::Vector{Float64},
        stepsizes::Vector{Float64},
        npts::Int) -> Array{Int, 2}

Assign integer bin labels to the points of an embedding, storing the
labels in the preallocated array `A`.
"""
function assign_integer_bin_label_to_eachpoint!(
            A::AbstractArray{Int, 2},
            pts::AbstractArray{T, 2},
            axisminima::Vector{Float64},
            δs::Vector{Float64},
            npts::Int) where T
    @inbounds for i = 1:npts
        A[:, i] .= floor.(Int, abs.(axisminima .- pts[:, i]) ./ δs)
    end
end

"""
    assign_bin_labels(points, ϵ)

Consider a rectangular grid specified by ϵ. Assign bin labels to the provided
`points` by checking which bins each point fall into. Each points is given a
label which is an integer encoding of the origin of the bin it falls into.

The following `ϵ` will work:

* `ϵ::Int` divide each axis into `ϵ` intervals of the same size.
* `ϵ::Float` divide each axis into intervals of size `ϵ`.
* `ϵ::Vector{Int}` divide the i-th axis into `ϵᵢ` intervals of the same size.
* `ϵ::Vector{Float64}` divide the i-th axis into intervals of size `ϵᵢ`.

The points are assumed to be provided as an array where each point is a column.
"""
function assign_bin_labels(points, ϵ)
    # Make sure that the array contains points as columns.
    if size(points, 1) > size(points, 2)
        error("The dimension of the dataset exceeds the number of points.")
    end

    # How many points are there in the embedding, and what is its dimension?
    D = size(points, 1)
    npts = size(points, 2)

    if npts <= D
        error("Number of pts is less than dim=$D. Is every column a point?")
    end
    # Find the minima of the embedding and generate step
    # sizes along each axis
    bottom, stepsizes = minima_and_stepsizes(points, ϵ)
    if typeof(stepsizes) <: Union{Float64, Int}
        stepsizes = [stepsizes]
    end

    # Each points of the embedding gets assigned to one bin.
    # The coordinates of each point of the original embedding are
    # assigned an integer number indicating which bin along the respective
    # dimension it falls into.
    visited_bins_inds = zeros(Int, D, npts)
    assign_integer_bin_label_to_eachpoint!(
        visited_bins_inds,
        points,
        bottom,
        stepsizes,
        npts)

    return visited_bins_inds
end

"""
    assign_bin_labels(E::Embeddings.AbstractEmbedding, ϵ) -> Array{Int, 2}

Find bins visited by the reconstructed orbit and assign
to them integer tuples uniquely identifying the bins.

Each point of the embedding gets assigned one integer tuple label,
stored as column vectors in the returned array. If some bin
is visited more than once, there will be repeated columns.

# Details
Given a bin size ϵ, whics is `Union{Int, Float}` for cubic bins,
and `Union{Vector{Int}, Vector{Float64}}` for rectangular bins,
assign a tuple of integers uniquely identifying that bin.

Take, for example, the pair `(pᵢ, (n₁, n₂, n₃)`. Having a
3-element tuple associated with pᵢ means that the reconstruction
is 3D, so we have three coordinate axes - x₁, x₂ and x₃ - to
consider.

This generic example should be read as:
for point `pᵢ`, one must jump n₁ steps along x₁, n₂ steps
along x₂ and n₃ steps along x₃ (in units of ϵ₁, ϵ₂ and ϵ₃)
from the minima of each axis to reach the coordinates of `pᵢ`.

Each visited bin is thus uniquely identified by a tuple of
integers. `visited_bins_indices` assigns one such tuple
to each of the points in the embedding. These are gathered
in an array where column vectors represent the tuples
associated to each point.
"""
function assign_bin_labels(E::AbstractEmbedding, ϵ)
    assign_bin_labels(E.points, ϵ)
end

"""
    assign_coordinate_labels_to_eachpoint!(
            A::Array{Float64, 2},
            pts::Array{Float64, 2},
            axisminima::Vector{Float64},
            δs::Vector{Float64},
            npts::Int)

Assign bin labels to the points of an embedding as coordinate
relative to the minima along each coordinate axis. Store the
coordinate labels in the preallocated array `bin_origins`.
"""
function assign_coordinate_labels_to_eachpoint!(
        bin_origins::Array{Float64, 2},
        visited_bin_inds::Array{Int, 2},
        pts::Array{Float64, 2},
        axisminima::Vector{Float64},
        δs::Vector{Float64},
        n_orbit_pts::Int)
    for i = 1:n_orbit_pts
        bin_origins[:, i] = axisminima .+ (δs .* visited_bin_inds[:, i])
    end
end


"""
    assign_coordinate_labels(points, ϵ) -> Array{Float64, 2}

Consider a rectangular grid specified by ϵ. Assume the bin labels to the provided
`points` by checking which bins each point fall into. Each points is given a
label which is the coordinates of the origin of the bin it falls into.

Together with `ϵ`, the coordinates of the origins of the bins provide
complete information about a coarse graining that covers all visited
states of the system (when `points` represent the orbit).

The following `ϵ` will work:

* `ϵ::Int` divide each axis into `ϵ` intervals of the same size.
* `ϵ::Float` divide each axis into intervals of size `ϵ`.
* `ϵ::Vector{Int}` divide the i-th axis into `ϵᵢ` intervals of the same size.
* `ϵ::Vector{Float64}` divide the i-th axis into intervals of size `ϵᵢ`.

The points are assumed to be provided as an array where each point is a column.
"""
function assign_coordinate_labels(points, ϵ)
    # Make sure that the array contains points as columns.
    if size(points, 1) > size(points, 2)
        error("The dimension of the dataset exceeds the number of points.")
    end

    # How many points are there in the embedding, and what is its dimension?
    D = size(points, 1)
    npts = size(points, 2)

    if npts <= D
        error("Number of pts is less than dim=$D. Is every column a point?")
    end

    # Find the minima of the embedding and generate step
    # sizes along each axis.
    axisminima, stepsizes = minima_and_stepsizes(points, ϵ)
    visited_bin_inds = assign_bin_labels(points, ϵ)
    bin_origins = zeros(Float64, D, npts)

    n_orbit_points = size(points, 2)
    assign_coordinate_labels_to_eachpoint!(
        bin_origins,
        assign_bin_labels(points, ϵ),
        points,
        axisminima,
        stepsizes,
        n_orbit_points
    )

    return bin_origins
end


"""
    assign_coordinate_labels(E::Embeddings.AbstractEmbedding, ϵ) -> Array{Float64, 2}

Consider a rectangular grid specified by ϵ. Assume the bin labels to the
provided embedding by checking which bins each point fall into. Each points is
given a label which is the coordinates of the origin of the bin it falls into.

Together with `ϵ`, the coordinates of the origins of the bins provide
complete information about a coarse graining that covers all visited
states in the reconstruction/embedding.

The following `ϵ` will work:

* `ϵ::Int` divide each axis into `ϵ` intervals of the same size.
* `ϵ::Float` divide each axis into intervals of size `ϵ`.
* `ϵ::Vector{Int}` divide the i-th axis into `ϵᵢ` intervals of the same size.
* `ϵ::Vector{Float64}` divide the i-th axis into intervals of size `ϵᵢ`.
"""
function assign_coordinate_labels(E::AbstractEmbedding, ϵ)
    assign_coordinate_labels(E.points, ϵ)
end


"""
    assign_coordinate_labels(visited_bin_inds, points, ϵ)  -> Array{Float64, 2}

Consider a rectangular grid specified by ϵ. Assume that, given `ϵ`,
integer bin  labels have been assigned to each point and are stored in
`visited_bin_inds`. This array contains one column of integer bin
labels each of the points in `points`.

Here, we return an array of the same size as `visited_bin_inds`. However,
instead of the labels being integers, they are converted into the
coordinates of the origin of the corresponding bins.

Together with `ϵ`, the coordinates of the origins of the bins provide
complete information about a coarse graining that covers all visited
states of the system (when `points` represent the orbit).

The following `ϵ` will work:

* `ϵ::Int` divide each axis into `ϵ` intervals of the same size.
* `ϵ::Float` divide each axis into intervals of size `ϵ`.
* `ϵ::Vector{Int}` divide the i-th axis into `ϵᵢ` intervals of the same size.
* `ϵ::Vector{Float64}` divide the i-th axis into intervals of size `ϵᵢ`.

The points are assumed to be provided as an array where each point is a column.
"""
function assign_coordinate_labels(visited_bin_inds, points, ϵ)
    # Make sure that the array contains points as columns.
    if size(points, 1) > size(points, 2)
        error("The dimension of the dataset exceeds the number of points.")
    end

    # How many points are there in the embedding, and what is its dimension?
    D = size(points, 1)
    npts = size(points, 2)

    if npts <= D
        error("Number of pts is less than dim=$D. Is every column a point?")
    end

    # Find the minima of the embedding and generate step
    # sizes along each axis.
    axisminima, stepsizes = minima_and_stepsizes(points, ϵ)

    bin_origins = zeros(Float64, size(visited_bin_inds))

    n_orbit_points = size(points, 2)
    assign_coordinate_labels_to_eachpoint!(
        bin_origins,
        visited_bin_inds,
        points,
        axisminima,
        stepsizes,
        n_orbit_points
    )

    return bin_origins
end

"""
    assign_coordinate_labels(visited_bin_inds,
        E::Embeddings.AbstractEmbedding, ϵ)  -> Array{Float64, 2}

Consider a rectangular grid specified by ϵ. Assume that, given `ϵ`,
integer bin  labels have been assigned to each point and are stored in
`visited_bin_inds`. This array contains one column of integer bin
labels each of the points of the embedding.

Here, we return an array of the same size as `visited_bin_inds`. However,
instead of the labels being integers, they are converted into the
coordinates of the origin of the corresponding bins.

Together with `ϵ`, the coordinates of the origins of the bins provide
complete information about a coarse graining that covers all visited
states of the reconstructed state space.

The following `ϵ` will work:

* `ϵ::Int` divide each axis into `ϵ` intervals of the same size.
* `ϵ::Float` divide each axis into intervals of size `ϵ`.
* `ϵ::Vector{Int}` divide the i-th axis into `ϵᵢ` intervals of the same size.
* `ϵ::Vector{Float64}` divide the i-th axis into intervals of size `ϵᵢ`.
"""
function assign_coordinate_labels(visited_bin_inds, E::AbstractEmbedding, ϵ)
    assign_coordinate_labels(visited_bin_inds, E.points, ϵ)
end
