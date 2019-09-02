using RecipesBase

################################################################################
# Destriping results

@doc raw"""
    mutable struct DestripingData{T <: Real, O <: Healpix.Order}

Structure containing the result of a destriping operation. It contains
the following fields:

- `skymap`: a `PolarizedMap` containing the maximum-likelihood map
- `hitmap`: a map containing the weights of each pixel (this is not
  the hit count, as it is normalized over the value of ``σ^2`` for
  each sample in the TOD)
- `nobs_matrix`: an array of [`NobsMatrixelement`](@ref) objects,
  which can be used to determine which pixels were the most
  troublesome in the reconstruction of tehe I/Q/U components
- `baselines`: the computed baselines. These must be kept as a list of
  `RunLengthArray` objects
- `stopping_factors`: sequence of stopping factors, one for
  each iteration of the CG algorithm
- `threshold`: upper limit on the tolerable error for the Conjugated
  Gradient method (optional, default is `1e-9`). See
  [`calc_stopping_factor`](@ref).
- `max_iterations`: maximum number of allowed iterations for the
  Conjugated Gradient algorithm (optional, default is `1000`).
- `use_preconditioner`: a Boolean flag telling whether a
  preconditioner should be used or not (optional, default is
  `true`). Usually you want this to be `true`.

The structure provides only one constructor, which accepts the
following parameters:

- `nside`: resolution of `skymap` and `hitmap`

- `obs_list`: vector of [`Observation`](@ref); it is used to determine
  which pixels in the map are going to be observed

- `runs`: list of vectors (one for each element in `obs_list`),
  containing the number of samples to be included in each baseline for
  each observation

The constructor accepts the following keywords as well:

- `threshold` (default: `1e-9`)

- `max_iterations` (default: 1000)

- `use_preconditioner` (default: `true`)

The function [`destripe!`](@ref) use `DestripingData` to return the
result of its computation.

"""
mutable struct DestripingData{T <: Real, O <: Healpix.Order}
    skymap::Healpix.PolarizedMap{T, O}
    hitmap::Healpix.Map{T, O}
    nobs_matrix::Vector{NobsMatrixElement{T}}
    baselines::Vector{RunLengthArray{Int, T}}
    stopping_factors::Vector{T}
    threshold::Float64
    max_iterations::Int
    use_preconditioner::Bool

    function DestripingData{T,O}(
        nside,
        obs_list::Vector{Observation{T}},
        runs;
        threshold = 1e-9,
        max_iterations = 1000,
        use_preconditioner = true,
    ) where {T <: Real, O <: Healpix.Order}

        @assert length(obs_list) == length(runs)
        @assert threshold > 0.0
        @assert max_iterations > 0

        npix = Healpix.nside2npix(nside)
        nobs_matrix = [NobsMatrixElement{T}() for i in 1:npix]
        compute_nobs_matrix!(nobs_matrix, obs_list)

        new(
            Healpix.PolarizedMap{T, O}(
                zeros(npix),
                zeros(npix),
                zeros(npix),
            ),
            Healpix.Map{T,O}(nside),
            nobs_matrix,
            [RunLengthArray{Int,T}(x, zeros(length(x))) for x in runs],
            T[],  # List of stopping factors
            threshold,
            max_iterations,
            use_preconditioner,
        )
    end

end

function Base.show(io::IO, d::DestripingData)
    print(io, "DestripingData(NSIDE=$(d.hitmap.resolution.nside))")
end

function Base.show(io::IO, ::MIME"text/plain", d::DestripingData)
    # Count how many pixels have been observed in the map
    obspix = 0
    for elem in d.nobs_matrix
        elem.neglected || (obspix += 1)
    end

    # Put all the baselines of each observation into one long list
    # (without allocating memory!)
    flattened_baselines = Iterators.flatten([values(x) for x in d.baselines])

    println(
        io,
        @sprintf(
            """Destriping data:
NSIDE of the map........................ %d
Number of observed pixels............... %d (%.1f%%)
Number of iterations.................... %d/%d
Best convergence factor................. %s (threshold: %e)
Number of observations.................. %d
Average value of the baselines.......... %e
RMS of the baselines.................... %e
Preconditioner.......................... %s
""",
            d.hitmap.resolution.nside,
            obspix,
            100.0 * obspix / length(d.nobs_matrix),
            length(d.stopping_factors),
            d.max_iterations,
            isempty(d.stopping_factors) ? "none" : @sprintf("%e", minimum(d.stopping_factors)),
            d.threshold,
            length(d.baselines),
            mean(flattened_baselines),
            std(flattened_baselines),
            "$(d.use_preconditioner)",
        )
    )
end


@doc raw"""
    reset_maps!(d::DestripingData{T, O}) where {T <: Real, O <: Healpix.Order}

Set the skymap and the hitmap in `d` to zero. Nothing is done on the
other fields.

"""
function reset_maps!(d::DestripingData{T, O}) where {T <: Real, O <: Healpix.Order}
    d.skymap.i .= 0.0
    d.skymap.q .= 0.0
    d.skymap.u .= 0.0

    d.hitmap .= 0.0
end

@recipe function plot_destriping_data(d::DestripingData{T, O}) where {T <: Real, O <: Healpix.Order}
    seriestype := :path
    xlabel := "Iteration number"
    ylabel := "Stopping factor"
    linecolor := :black
    
    isempty(d.stopping_factors) && return ([0.0], [0.0])
    num_of_steps = length(d.stopping_factors)

    @series begin
        # Horizontal line showing the threshold
        seriestype := :path
        linecolor := :red
        ([1, num_of_steps], [d.threshold, d.threshold])
    end

    ((1:num_of_steps), d.stopping_factors)
end

@doc raw"""
    plot(d::DestripingData{T, O}) where {T <: Real, O <: Healpix.Order}

Plot the convergence plot for a destriping solution.
"""
plot_destriping_data
