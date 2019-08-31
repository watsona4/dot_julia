"""
    marginal_visitation_freq(along_which_axes::Union{Int, Vector{Int}, AbstractUnitRange{Int}},
        visited_bins::Array{T, 2}) where T


Calculate marginal or joint visitation frequencies for a pre-binned set of
points. Each column in `visited_bins` corresponds to a unique point, and
contains the coordinate or integer representation of the bin containing that
point.

## Arguments
- `visited_bins`: Contains a representation of the boxes containing each point.
- `along_which_axes`: Controls which axes to take the marginal visitation
    frequencies along. Setting `along_which_axes` to a range 1:D, where
    D is the dimension of the corresponding state space, corresponds to taking the
    joint visitation frequency (basically, a D-dimensional histogram).
- `npts`: The number of points in the embedding, which is used as a
    normalization factor.
"""
function marginal_visitation_freq(
        along_which_axes::Union{Int, Vector{Int}, AbstractUnitRange{Int}},
        visited_bins::AbstractArray{T, 2}) where T
    if typeof(along_which_axes) <: Int
        along_which_axes = [along_which_axes]
    end
    # The number of points to which we have assigned bins
    npts = size(visited_bins, 2)

    # Assuming there are M unique bins (or, equivalently, integer tuples),
    # groupslices(visited_bins_inds, 2) returns a vector of indices,
    # in which each visited bin label is associated with the i-th unique
    # bin. For example, if slices = [1, 2, 3, 1, 2, 3, 7, ...], then points
    # p₁ and p₄ are repeated (have identical labels), p₂ and p₅ are repeated,
    # and p₃ and p₆ are repeated.
    #
    # Subsetting some of the rows are equivalent to estimating the marginal
    # along the corresponding axes. If along_which_axes = 1:n_axes, then we're
    # computing the joint frequency distribution.
    slices = groupslices(visited_bins[along_which_axes, :], 2)

    # The groupinds function takes these indices and groups the indices
    # corresponding to repeated points. For the example in the comment
    # above, group_repeated_inds = [[1, 4], [2, 5], [3, 6],
    # [7, indices of potential points shared with p₇], ....].
    group_repeated_inds = groupinds(slices)

    # Computing the joint probability for pᵢ is now just a matter of counting
    # the number of times each visited bin is visited. The number of times
    # the ith visited bin is visited by the orbit is then simply counting
    # how many elements there are in group_repeated_inds[i].
    n_visited_states = length(group_repeated_inds)

    # We'll now loop over one bit at a time, counting how many times
    # the bin is visited, then get visitation frequency for that bin
    # by dividing the number of times it is visited by the total
    # number of points.
    m = Vector{Float64}(undef, n_visited_states) # preallocate marginal vector
    @inbounds for i = 1:n_visited_states
        m[i] = length(group_repeated_inds[i]) / npts
    end

    return m
end

"""
    marginal_visitation_freq(
        along_which_axes::Union{Int, Vector{Int}, AbstractUnitRange{Int}},
        points::Array{T, 2},
        ϵ) where T

Compute marginal visitation frequencies for a set of `points`, given a partition
scheme `ϵ`. The following `ϵ` will work:

* `ϵ::Int` divide each axis into `ϵ` intervals of the same size.
* `ϵ::Float` divide each axis into intervals of size `ϵ`.
* `ϵ::Vector{Int}` divide the i-th axis into `ϵᵢ` intervals of the same size.
* `ϵ::Vector{Float64}` divide the i-th axis into intervals of size `ϵᵢ`.


The argument `along_which_axes` controls which axes to take the marginal
visitation frequencies along. Setting `along_which_axes` to a range 1:D,
where D is the dimension of the corresponding state space, corresponds to
taking the joint visitation frequency.
"""
function marginal_visitation_freq(
            along_which_axes::Union{Int, Vector{Int}, AbstractUnitRange{Int}},
            points::AbstractArray{T, 2},
            ϵ) where T
    # Make sure that the array contains points as columns.
    if size(points, 1) > size(points, 2)
        error("The dimension of the dataset exceeds the number of points.")
    end

    N = size(points, 1)
    visited_bins = assign_bin_labels(points, ϵ)
    marginal_visitation_freq(along_which_axes, visited_bins)
end

"""
    marginal_visitation_freq(
        along_which_axes::Union{Int, Vector{Int}, AbstractUnitRange{Int}},
        E::AbstractEmbedding,
        ϵ)

Compute marginal visitation frequencies for an embedding, given a partition
scheme `ϵ`. The following `ϵ` will work:

* `ϵ::Int` divide each axis into `ϵ` intervals of the same size.
* `ϵ::Float` divide each axis into intervals of size `ϵ`.
* `ϵ::Vector{Int}` divide the i-th axis into `ϵᵢ` intervals of the same size.
* `ϵ::Vector{Float64}` divide the i-th axis into intervals of size `ϵᵢ`.


The argument `along_which_axes` controls which axes to take the marginal
visitation frequencies along. Setting `along_which_axes` to a range 1:D,
where D is the dimension of the corresponding state space, corresponds to
taking the joint visitation frequency.
"""
function marginal_visitation_freq(
            along_which_axes::Union{Int, Vector{Int}, AbstractUnitRange{Int}},
            E::AbstractEmbedding, ϵ)
    marginal_visitation_freq(along_which_axes, E.points, ϵ)
end

marginal_visitfreq = marginal_visitation_freq
