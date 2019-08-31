import StateSpaceReconstruction

"""
    mutable struct RectangularInvariantMeasure{T} <: InvariantMeasure where {T}
        E::pts::AbstractArray{T, 2}
        ϵ::Union{Int, Float, Vector{Int}, Vector{Float64}}
        visited_bins_inds::AbstractArray{Int,2}
        visited_bins_coordinates::AbstractArray{Float64,2}
        binvisits::BinVisits
        transfermatrix::RectangularBinningTransferOperator
        measure::InvariantDistribution
    end

A RectangularInvariantMeasure created from a set of points representing a
state space by discretizing the state space into rectangular bins with
edge lengths dictated by the binning scheme `ϵ`. The invariant measure is
then computed from an approximation to the transfer operator over the
discretized state space.

## Fields
- **`pts`**: The points for which to estimate the invariant measure.
- **`ϵ`**: The binning scheme. The following `ϵ` are valid:
    - `ϵ::Int` divides each axis into `ϵ` intervals of the same size.
    - `ϵ::Float` divides each axis into intervals of size `ϵ`.
    - `ϵ::Vector{Int}` divides the i-th axis into `ϵᵢ` intervals of the same size.
    - `ϵ::Vector{Float64}` divides the i-th axis into intervals of size `ϵᵢ`.
- **`visited_bins_inds`**: Counting from the start of each
    coordinate axis in steps dictated by `ϵ`, which bins do each
    of the points lie in? Is an array containing one column vector
    of indices for each point (one index per coordinate axis).
- **`visited_bins_coordinates`**: The coordinates of the origin
    of each bin that is visited. Each bin (rectangular box) has edge
    lengths given by `ϵ`.
- **`binvisits`**: A `BinVisits` instance, indicating which points
    visits which bin.
- **`transfermatrix`**: The transfer matrix from which the invariant
    measure is obtained.
- **`measure`**: The invariant measure over the visited bins.
"""
mutable struct RectangularInvariantMeasure{T} <: InvariantMeasure where {T}
    pts::AbstractArray{T, 2}
    ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}}
    visited_bins_inds::AbstractArray{Int,2}
    visited_bins_coordinates::AbstractArray{Float64,2}
    binvisits::BinVisits
    transfermatrix::RectangularBinningTransferOperator
    measure::InvariantDistribution
end

"""
    RectangularInvariantMeasure(pts::AbstractArray{T, 2},
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}},
        estimator = transferoperator_grid;
        kwargs...) where {T}

Estimate a RectangularInvariantMeasure from a state space reconstruction `E`.
This is done by discretizing the state space into rectangular bins with
edge lengths dictated by the binning scheme `ϵ`. We then approximate the
transfer operator over the discretized state space, and compute the
invariant measure over the bins from the transfer operator.

## Arguments
- **`pts`**: The points for which to estimate the invariant measure.
- **`ϵ`**: The binning scheme. The following `ϵ` are valid:
    - `ϵ::Int` divides each axis into `ϵ` intervals of the same size.
    - `ϵ::Float64` divides each axis into intervals of size `ϵ`.
    - `ϵ::Vector{Int}` divides the i-th axis into `ϵᵢ` intervals of the same size.
    - `ϵ::Vector{Float64}` divides the i-th axis into intervals of size `ϵᵢ`.
- **`estimator`**: A transfer operator estimator yielding a
    `PerronFrobenius.RectangularBinningTransferOperator`. Defaults to
     `transferoperator_grid`.
- **`kwargs`**: Keyword arguments when calling `invariantmeasure` on the
    transfer operator.
"""
function RectangularInvariantMeasure(pts::AbstractArray{T, 2},
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}},
        estimator = transferoperator_grid;
        kwargs...) where {T}

    if estimator == transferoperator_grid
        # Identify which bins of the partition resulting from using ϵ each
        # point of the embedding visits.

        # The indices, counting from the start of each coordinate axis
        # in steps given by ϵ
        visited_bins_inds = assign_bin_labels(pts, ϵ)

        # The coordinate of the bin origins
        visited_bins_coordinates = assign_coordinate_labels(pts, ϵ)

        # Which are the visited bins, which points
        # visits which bin, repetitions, etc...
        binvisits = organize_bin_labels(visited_bins_inds)

        # Use that information to estimate transfer operator
        TO = transferoperator_binvisits(binvisits)

        # Compute invariant measure
        ivm = invariantmeasure(TO; kwargs...)

        RectangularInvariantMeasure(
            pts,
            ϵ,
            visited_bins_inds,
            visited_bins_coordinates,
            binvisits,
            TO,
            ivm
        )
    end
end


"""
    RectangularInvariantMeasure(E::ET,
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}},
        estimator = transferoperator_grid;
        kwargs...) where {ET <: StateSpaceReconstruction.AbstractEmbedding}

Estimate a RectangularInvariantMeasure from a state space reconstruction `E`.
This is done by discretizing the state space into rectangular bins with
edge lengths dictated by the binning scheme `ϵ`. We then approximate the
transfer operator over the discretized state space, and compute the
invariant measure over the bins from the transfer operator.

## Arguments
- **`E`**: The embedding for which to estimate the invariant measure.
- **`ϵ`**: The binning scheme. The following `ϵ` are valid:
    - `ϵ::Int` divides each axis into `ϵ` intervals of the same size.
    - `ϵ::Float64` divides each axis into intervals of size `ϵ`.
    - `ϵ::Vector{Int}` divides the i-th axis into `ϵᵢ` intervals of the same size.
    - `ϵ::Vector{Float64}` divides the i-th axis into intervals of size `ϵᵢ`.
- **`estimator`**: A transfer operator estimator yielding a
    `PerronFrobenius.RectangularBinningTransferOperator`. Defaults to
     `transferoperator_grid`.
- **`kwargs`**: Keyword arguments when calling `invariantmeasure` on the
    transfer operator.
"""
function RectangularInvariantMeasure(E::ET,
        ϵ::Union{Int, Float64, Vector{Int}, Vector{Float64}},
        estimator = transferoperator_grid;
        kwargs...) where {ET <: StateSpaceReconstruction.AbstractEmbedding}


    if estimator == transferoperator_grid
        # Identify which bins of the partition resulting from using ϵ each
        # point of the embedding visits.

        # The indices, counting from the start of each coordinate axis
        # in steps given by ϵ
        visited_bins_inds = assign_bin_labels(E, ϵ)

        # The coordinate of the bin origins
        visited_bins_coordinates = assign_coordinate_labels(E, ϵ)

        # Which are the visited bins, which points
        # visits which bin, repetitions, etc...
        binvisits = organize_bin_labels(visited_bins_inds)

        # Use that information to estimate transfer operator
        TO = transferoperator_binvisits(binvisits)

        # Compute invariant measure
        ivm = invariantmeasure(TO; kwargs...)

        RectangularInvariantMeasure(
            E.points,
            ϵ,
            visited_bins_inds,
            visited_bins_coordinates,
            binvisits,
            TO,
            ivm
        )
    end
end
