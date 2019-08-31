"""
    transferoperator_binvisits(bv::BinVisits;
                allocate_frac = 1.0,
                boundary_condition = :none)

Estimate transfer operator from information about which bin
gets visited by which points of the orbit.

## Transition probabilities
To determine the transition probabilities, we pre-allocate two index vectors
(`I` and `J`) and a probability vector (`P`). After the transition probabilities
have been determined, the vectors are combined into a sparse matrix (the
transfer matrix), which typically have very few nonzero entries (often only a
few percent).

## Memory allocation
To not allocate too much memory, `allocate_frac` controls what fraction of the
total number of possible transitions (``n_{states}^2``) we pre-allocate for.

## Example usage

```
# Random orbit.
orbit = rand(1000, 3)
x, y, z = orbit[:, 1], orbit[:, 2], orbit[:, 3]

# Embedding E = {(y(t+1), y(t), x(t))}
E = embed([x, y], [2, 2, 1], [1, 0, 0]);

# Which bin sizes to use along each dimension?
ϵ = [.4, .2, .4]

# Identify which bins of the partition resulting
# from using ϵ each point of the embedding visits.
visited_bins = assign_bin_labels(E, ϵ)

# Which are the visited bins, which points
# visits which bin, repetitions, etc...
binvisits = organize_bin_labels(visited_bins)

# Use that information to estimate transfer operator
TO = transferoperator(binvisits)

# Verify that TO is Markov (NB. last row might be zero!,
# then this test might fail)
all(sum(TO, 2) .≈ 1)
```
"""
function transferoperator_binvisits(bv::BinVisits;
                allocate_frac = 1.0,
                boundary_condition = :none)

    valid_boundary_conditions = [:none, :exclude, :circular, :invariantize]
    if !(boundary_condition ∈ valid_boundary_conditions)
        error("Boundary condition $boundary_condition not valid.")
    end

    if !(0 < allocate_frac <= 1)
        error("allocate_frac needs to be on the interval (0, 1]")
    end

    first_visited_by = bv.first_visited_by
    visitors = bv.visitors
    visits_whichbin = bv.visits_whichbin
    n_visited_bins = length(first_visited_by)


    # Initialise transfer (Perron-Frobenius) operator as a sparse matrix
    # (keep track of indices and values in separate columns for now)
    n_possible_nonzero_entries = n_visited_bins^2
    N = ceil(Int, n_possible_nonzero_entries / allocate_frac)

    I = zeros(Int32, N)
    J = zeros(Int32, N)
    P = zeros(Float64, N)

    # Preallocate target index for the case where there is only
    # one point of the orbit visiting a bin.
    target_bin_j::Int = 0
    n_visitsᵢ::Int = 0

    # Keep track of how many transitions we've considered.
    transition_counter = 0

    if boundary_condition == :circular
        #warn("Using circular boundary condition")
        append!(visits_whichbin, [1])
    elseif boundary_condition == :random
        #warn("Using random circular boundary condition")
		append!(visits_whichbin, [rand(1:length(visits_whichbin))])
	end

    # Loop over the visited bins bᵢ
    for i in 1:n_visited_bins
        # How many times is this bin visited?
        n_visitsᵢ = length(visitors[i])

        # If both conditions below are true, then there is just one
        # point visiting the i-th bin. If there is only one visiting point and
        # it happens to be the last, we skip it, because we don't know its
        # image.
        if n_visitsᵢ == 1 && !(i == visits_whichbin[end])
            transition_counter += 1
            # To which bin does the single point visiting bᵢ jump if we
            # shift it one time step ahead along its orbit?
            target_bin_j = visits_whichbin[visitors[i][1] + 1][1]

            # We now know that exactly one point (the i-th) does the
            # transition from i to the target j.
            I[transition_counter] = i
            J[transition_counter] = target_bin_j
            P[transition_counter] = 1
        end
        # If more than one point of the orbit visits the i-th bin, we
        # identify the visiting points and track which bins bⱼ they end up
        # in after the forward linear map of the points.
        if n_visitsᵢ > 1
            timeindices_visiting_pts = visitors[i]

            # TODO: Introduce circular boundary condition. Simply excluding
            # might lead to a cascade of loosing points.

            # If bᵢ is the bin visited by the last point in the orbit, then
            # the last entry of `visiting_pts` will be the time index of the
            # last point of the orbit. In the next time step, that point will
            # have nowhere to go along its orbit (precisely because it is the
            # last data point). Thus, we exclude it.
            if i == visits_whichbin[end]
                #warn("Removing last point")
                n_visitsᵢ = length(timeindices_visiting_pts) - 1
                timeindices_visiting_pts = timeindices_visiting_pts[1:(end - 1)]
            end

            # To which boxes do each of the visitors to bᵢ jump in the next
            # time step?
            target_bins = visits_whichbin[timeindices_visiting_pts .+ 1]
            unique_target_bins = unique(target_bins)

            # Count how many points jump from the i-th bin to each of
            # the unique target bins, and use that to calculate the transition
            # probability from bᵢ to bⱼ.
            for j in 1:length(unique_target_bins)
                n_transitions_i_to_j = sum(target_bins .== unique_target_bins[j])

                transition_counter += 1
                I[transition_counter] = i
                J[transition_counter] = unique_target_bins[j]
                P[transition_counter] = n_transitions_i_to_j / n_visitsᵢ
            end
        end
    end

    # Combine indices and values into a sparse representation of the Perron-
    # Frobenius operator (transfer operator). Filter out the nonzero entries.
    # The number of rows in the matrix is given by the number of unique points
    # we have in the embedding.
    TO = Array(sparse(I[1:transition_counter],
                J[1:transition_counter],
                P[1:transition_counter],
                n_visited_bins, n_visited_bins))

    # There may be boxes which are visited by points of the orbit, but not by
    # any image points.
    # zc = zerocols(TO)
    # l = length(zc)
    # if l > 0
    #     col = zc[1]
    #     warn("There were $l all-zero columns. Column $col is the culprit -> normalizing ...")
    #     TO = TO ./ sum(TO, 2)
    # end
    # If the first bin is not visited, make every point starting in that bin
    # jump to the same bin with probability one.
    # zc = zerocols(TO)
    # if length(zc) > 0
    #     warn("There were $l all-zero columns: column $col")
    #     @show zc
    #     i = zc[1]
    #     TO[i, 1] = 1.0
    # end

    RectangularBinningTransferOperator(TO)
end



"""
    transferoperator_grid(E::Embeddings.AbstractEmbedding,
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}};
        allocate_frac::Float64 = 1.0,
        boundary_condition = :exclude) ->
        RectangularBinningTransferOperator

Estimates the transfer operator for an embedding.

## Discretization scheme

The binning scheme is specified by `ϵ`, and the following `ϵ` are valid:

- `ϵ::Int` divides each axis into `ϵ` intervals of the same size.
- `ϵ::Float` divides each axis into intervals of size `ϵ`.
- `ϵ::Vector{Int}` divides the i-th axis into `ϵᵢ` intervals of the same size.
- `ϵ::Vector{Float64}` divides the i-th axis into intervals of size `ϵᵢ`.

## Memory allocation

`allocate_frac` controls what fraction of the total number of
possible transitions (``n_{states}^2``) we pre-allocate for. For short time
series, you should leave this at the default value `1.0`. However, for longer
time series, the transition matrix is sparse (usually, less than ``10\\%`` of
the entries are nonzero). In these case, you can safely lower `allocate_frac`.

## Boundary conditions (dealing with the last point)

`boundary_condition` controls what to do with the forward
map of the last point of the embedding. The default, `:exclude`,
simply ignores the last point.

"""
function transferoperator_grid(
        E::Embeddings.AbstractEmbedding,
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}};
        allocate_frac::Float64 = 1.0,
        boundary_condition::Symbol = :none)


    valid_boundary_conditions = [:none, :exclude, :circular,
                                :invariantize]
    if !(boundary_condition ∈ valid_boundary_conditions)
        error("Boundary condition $boundary_condition not valid.")
    end

    if boundary_condition == :invariantize
        warn("Invariantizing embedding")
        E = invariantize(E)
    end

    # Identify which bins of the partition resulting from using ϵ each
    # point of the embedding visits.
    visited_bins = assign_bin_labels(E, ϵ)

    # Which are the visited bins, which points
    # visits which bin, repetitions, etc...
    binvisits = organize_bin_labels(visited_bins)

    # Use that information to estimate transfer operator
    transferoperator_binvisits(binvisits,
						allocate_frac = allocate_frac,
						boundary_condition = boundary_condition)
end


"""
    transferoperator_grid(pts::AbstractArray{T, 2},
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}};
        allocate_frac::Float64 = 1.0,
        boundary_condition = :none) where T ->
        RectangularBinningTransferOperator

Estimates the transfer operator for a set of points, given as a
    `dim`-by-`npoints` array.

## Discretization scheme

The binning scheme is specified by `ϵ`, and the following `ϵ` are valid:

- `ϵ::Int` divides each axis into `ϵ` intervals of the same size.
- `ϵ::Float` divides each axis into intervals of size `ϵ`.
- `ϵ::Vector{Int}` divides the i-th axis into `ϵᵢ` intervals of the same size.
- `ϵ::Vector{Float64}` divides the i-th axis into intervals of size `ϵᵢ`.

## Memory allocation

`allocate_frac` controls what fraction of the total number of
possible transitions (``n_{states}^2``) we pre-allocate for. For short time
series, you should leave this at the default value `1.0`. However, for longer
time series, the transition matrix is sparse (usually, less than ``10\\%`` of
the entries are nonzero). In these case, you can safely lower `allocate_frac`.

## Boundary conditions (dealing with the last point)
`boundary_condition` controls what to do with the forward
map of the last point of the embedding. The default, `:exclude`,
simply ignores the last point.

"""
function transferoperator_grid(
        points::AbstractArray{T, 2},
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}};
        allocate_frac::Float64 = 1.0,
        boundary_condition = :none) where T

    # Identify which bins of the partition resulting from using ϵ each
    # point of the embedding visits.
    visited_bins = assign_bin_labels(points, ϵ)

    # Which are the visited bins, which points
    # visits which bin, repetitions, etc...
    binvisits = organize_bin_labels(visited_bins)

    # Use that information to estimate transfer operator
    transferoperator_binvisits(binvisits,
                        allocate_frac = allocate_frac,
                        boundary_condition = boundary_condition)
end

export transferoperator_binvisits, transferoperator_grid

include("gridestimator_average.jl")
